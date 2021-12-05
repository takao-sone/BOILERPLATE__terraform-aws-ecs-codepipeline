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
