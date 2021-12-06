# ALB ==============================================
resource "aws_alb" "alb" {
  name               = "${var.project_name}-ingress-alb"
  internal           = false
  ip_address_type    = "ipv4"
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [aws_security_group.alb_sg.id]

  tags = {
    Name = "${var.project_name}-ingress-alb"
  }
}

# ALB Listener ==============================================
resource "aws_alb_listener" "alb_http_listener" {
  load_balancer_arn = aws_alb.alb.arn
  protocol          = "HTTP"
  port              = 80

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.alb_blue_tg.arn
  }

  lifecycle {
    ignore_changes = [default_action]
  }

  tags = {
    Name = "${var.project_name}-alb-http-listener"
  }
}

resource "aws_alb_listener" "alb_http_test_listener" {
  load_balancer_arn = aws_alb.alb.arn
  protocol          = "HTTP"
  port              = 10081

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.alb_green_tg.arn
  }
  lifecycle {
    ignore_changes = [default_action]
  }

  tags = {
    Name = "${var.project_name}-alb-http-test-listener"
  }
}

# ALB Target Group ==============================================
resource "aws_alb_target_group" "alb_blue_tg" {
  vpc_id      = var.vpc_id
  name        = "${var.project_name}-blue-tg"
  target_type = "ip"
  protocol    = "HTTP"
  port        = 80

  health_check {
    path                = "/healthcheck"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 15
    matcher             = "200"
  }

  #  lifecycle {
  #    create_before_destroy = true
  #  }

  tags = {
    Name = "${var.project_name}-blue-tg"
  }
}

resource "aws_alb_target_group" "alb_green_tg" {
  vpc_id      = var.vpc_id
  name        = "${var.project_name}-green-tg"
  target_type = "ip"
  protocol    = "HTTP"
  port        = 80

  health_check {
    path                = "/healthcheck"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 15
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-green-tg"
  }
}

# Security Group ==============================================
resource "aws_security_group" "alb_sg" {
  vpc_id = var.vpc_id
  name   = "${var.project_name}-ingress-sg"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 10081
    to_port     = 10081
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ingress-sg"
  }
}
