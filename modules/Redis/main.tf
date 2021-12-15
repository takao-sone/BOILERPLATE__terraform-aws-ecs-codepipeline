# Elastic Cache ===============================
resource "aws_elasticache_cluster" "redis_cluster" {
  cluster_id           = "${var.project_name}-redis-cluster"
  az_mode              = "single-az"
  engine               = "redis"
  engine_version       = "6.x"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis6.x"
  port                 = 6379
  security_group_ids = [
    aws_security_group.redis_security_group.id,
  ]
  snapshot_retention_limit = 0
  subnet_group_name        = aws_elasticache_subnet_group.redis_subnet_group.name
  tags = {
    Name = "${var.project_name}-redis-cluster"
  }
}

# Subnet Group ==============================================
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "${var.project_name}-redis-subnet-group"
  subnet_ids = var.private_redis_subnet_ids

  tags = {
    Name = "${var.project_name}-redis-subnet-group"
  }
}

# Security Group ===============================
resource "aws_security_group" "redis_security_group" {
  vpc_id = var.vpc_id
  name   = "${var.project_name}-redis-sg"

  ingress {
    protocol        = "tcp"
    from_port       = 6379
    to_port         = 6379
    security_groups = [var.app_container_security_group_id]
  }

  tags = {
    Name = "${var.project_name}-redis-sg"
  }
}

