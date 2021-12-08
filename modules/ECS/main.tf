# ECR ==============================================
resource "aws_ecr_repository" "app_ecr_repo" {
  name                 = "${var.project_name}-app-ecr-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-app-ecr-repo"
  }
}

resource "aws_ecr_lifecycle_policy" "ecr_lifecycle_policy" {
  repository = aws_ecr_repository.app_ecr_repo.name
  policy     = file("${path.module}/data/ecr_lifecycle_policy.json")
}

# Cluster ==============================================
resource "aws_ecs_cluster" "cluster" {
  name = "${var.project_name}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-ecs-cluster"
  }
}

# Service ==============================================
resource "aws_ecs_service" "app" {
  name                               = "${var.project_name}-app-ecs-service"
  launch_type                        = "FARGATE"
  task_definition                    = aws_ecs_task_definition.app.arn
  cluster                            = aws_ecs_cluster.cluster.arn
  desired_count                      = 2
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 120

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    subnets         = var.app_service_subnet_ids
    security_groups = [aws_security_group.container.id]
  }

  load_balancer {
    container_name   = var.app_container_name
    container_port   = 80
    target_group_arn = var.app_service_blue_target_group_arn
  }

  service_registries {
    registry_arn = aws_service_discovery_service.service_discovery.arn
  }

  lifecycle {
    ignore_changes = [desired_count, task_definition, load_balancer]
  }
}

# Service Discovery ==============================================
resource "aws_service_discovery_service" "service_discovery" {
  name = "${var.project_name}-ecs-service-discovery"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.service_discovery_dns_namespace.id
    dns_records {
      ttl  = 60
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }

  tags = {
    Name = "${var.project_name}-service-discovery"
  }
}

resource "aws_service_discovery_private_dns_namespace" "service_discovery_dns_namespace" {
  name = "${var.project_name}-local"
  vpc  = var.vpc_id
}

# Task Definition ==============================================
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-app-task-definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  task_role_arn            = aws_iam_role.ecs_app_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_app_task_execution_role.arn
  container_definitions    = jsonencode(local.container_definitions)

  tags = {
    Name = "${var.project_name}-app-task-definition"
  }
}

# FIXME: taskdef.jsonと同一設定??
locals {
  container_definitions = [
    {
      name              = var.app_container_name
      image             = aws_ecr_repository.app_ecr_repo.repository_url
      memoryReservation = 512
      cpu               = 256
      essential         = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver     = "awslogs"
        secretOptions = null
        options = {
          awslogs-group         = var.ecs_log_group_name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "${var.project_name}-ecs"
        }
      }
    }
  ]
}

# Auto Scaling ==============================================
resource "aws_appautoscaling_target" "autoscaling_target" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  #  lifecycle {
  #    ignore_changes = [role_arn]
  #  }
}

resource "aws_appautoscaling_policy" "autoscaling_policy" {
  name               = "${var.project_name}-ecs-scalingpolicy"
  resource_id        = aws_appautoscaling_target.autoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.autoscaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.autoscaling_target.service_namespace
  policy_type        = "TargetTrackingScaling"
  target_tracking_scaling_policy_configuration {
    target_value       = 80
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

# Security Group ===============================
resource "aws_security_group" "container" {
  vpc_id = var.vpc_id
  name   = "${var.project_name}-container-sg"

  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [var.alb_security_group_id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-container-sg"
  }
}

# Cloud Watch ==============================================
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = var.ecs_log_group_name
}

# IAM Role =============================================
resource "aws_iam_role" "ecs_app_task_execution_role" {
  name               = "${var.project_name}-ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role_assume_role_policy_document.json

  tags = {
    Name = "${var.project_name}-ecsTaskExecutionRole"
  }
}

resource "aws_iam_role" "ecs_app_task_role" {
  name               = "${var.project_name}-ecsTaskRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_role_assume_role_policy.json

  tags = {
    Name = "${var.project_name}-ecsTaskRole"
  }
}

# IAM Role Policy Attachment =============================================
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_app_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Policy =============================================
data "aws_iam_policy_document" "ecs_task_execution_role_assume_role_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_task_role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
