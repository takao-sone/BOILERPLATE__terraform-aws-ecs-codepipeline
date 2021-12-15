# RDS Cluster ==============================================
resource "aws_rds_cluster" "rds_cluster" {
  cluster_identifier      = "${var.project_name}-rds-cluster"
  database_name           = replace(var.project_name, "-", "_")
  engine                  = "aurora-postgresql"
  backtrack_window        = 0
  backup_retention_period = 1
  copy_tags_to_snapshot   = false
  deletion_protection     = false
  enable_http_endpoint    = false
  enabled_cloudwatch_logs_exports = [
    "postgresql",
  ]
  engine_mode                         = "provisioned"
  engine_version                      = "13.4"
  iam_database_authentication_enabled = false
  iam_roles                           = []
  port                                = 5432
  preferred_backup_window             = "18:52-19:22"
  preferred_maintenance_window        = "sun:15:00-sun:15:30"
  skip_final_snapshot                 = true
  storage_encrypted                   = true
  tags = {
    Name = "${var.project_name}-rds-cluster"
  }

  master_username = var.rds_master_username
  master_password = var.rds_master_password
  vpc_security_group_ids = [
    aws_security_group.rds_sg.id,
  ]
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name

  # FIXME
  db_cluster_parameter_group_name = "default.aurora-postgresql13"
}

# RDS Cluster Instance ==============================================
resource "aws_rds_cluster_instance" "rds_cluster_instance" {
  cluster_identifier           = aws_rds_cluster.rds_cluster.id
  identifier                   = "${var.project_name}-rds-cluster-instance"
  # FIXME
  availability_zone            = "ap-northeast-1a"
  auto_minor_version_upgrade   = true
  copy_tags_to_snapshot        = false
  engine                       = aws_rds_cluster.rds_cluster.engine
  engine_version               = aws_rds_cluster.rds_cluster.engine_version
  instance_class               = "db.t4g.medium"
  monitoring_interval          = 0
  performance_insights_enabled = false
  promotion_tier               = 1
  publicly_accessible          = false
  db_subnet_group_name         = aws_db_subnet_group.rds_subnet_group.name
  tags = {
    Name = "${var.project_name}-rds-cluster-instance"
  }

  # FIXME
  db_parameter_group_name = "default.aurora-postgresql13"
}

# Subnet Group ==============================================
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = var.private_rds_subnet_ids

  tags = {
    Name = "${var.project_name}-rds-subnet-group"
  }
}

# Security Group ==============================================
resource "aws_security_group" "rds_sg" {
  vpc_id = var.vpc_id
  name   = "${var.project_name}-rds-sg"

  ingress {
    protocol        = "tcp"
    from_port       = 5432
    to_port         = 5432
    security_groups = [var.app_container_sg_id]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}