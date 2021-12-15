# VPC ===============================
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway ===============================
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# VPC Endpoint ===============================
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = aws_subnet.private_endpoint_egress_subnets[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]

  tags = {
    Name = "${var.project_name}-ecr-api-vpce"
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = aws_subnet.private_endpoint_egress_subnets[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]

  tags = {
    Name = "${var.project_name}-ecr-dkr-vpce"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.container_rt[*].id

  tags = {
    Name = "${var.project_name}-s3-vpce"
  }
}

resource "aws_vpc_endpoint" "ecs_awslogs" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_endpoint_egress_subnets[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-logs-vpce"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_endpoint_egress_subnets[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-ssm-vpce"
  }
}

# Subnet ===============================
resource "aws_subnet" "public_subnets" {
  count             = 2
  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = var.public_subnet_cidrs[count.index]

  tags = {
    Name = "${var.project_name}-public-ingress-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private_container_subnets" {
  count             = 2
  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = var.private_subnet_container_cidrs[count.index]

  tags = {
    Name = "${var.project_name}-private-container-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private_db_subnets" {
  count             = 2
  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = var.private_subnet_db_cidrs[count.index]

  tags = {
    Name = "${var.project_name}-private-db-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private_redis_subnets" {
  count             = 2
  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = var.private_subnet_redis_cidrs[count.index]

  tags = {
    Name = "${var.project_name}-private-redis-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private_endpoint_egress_subnets" {
  count             = 2
  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = var.private_subnet_endpoint_cidrs[count.index]

  tags = {
    Name = "${var.project_name}-private-egress-subnet-${count.index + 1}"
  }
}

# Route Table ===============================
resource "aws_route_table" "internet_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    gateway_id = aws_internet_gateway.igw.id
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name = "${var.project_name}-route-internet"
  }
}

resource "aws_route_table_association" "pub_sub_rt_association" {
  count          = length(aws_subnet.public_subnets)
  route_table_id = aws_route_table.internet_rt.id
  subnet_id      = aws_subnet.public_subnets[count.index].id
}

resource "aws_route_table" "container_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}-route-app"
  }
}

resource "aws_route_table_association" "container" {
  count          = length(aws_subnet.private_container_subnets)
  route_table_id = aws_route_table.container_rt.id
  subnet_id      = aws_subnet.private_container_subnets[count.index].id
}

# Security Group ===============================
resource "aws_security_group" "vpc_endpoint" {
  vpc_id = aws_vpc.vpc.id
  name   = "${var.project_name}-vpce-sg"

  ingress {
    protocol        = "tcp"
    from_port       = 443
    to_port         = 443
    security_groups = [var.app_container_security_group_id]
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-vpce-sg"
  }
}

# Data ===============================
data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}
