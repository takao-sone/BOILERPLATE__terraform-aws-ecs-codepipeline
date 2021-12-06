# Base ========================
variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

# ========================
variable "vpc_cidr" {
  type = string
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_container_cidrs" {
  type = list(string)
}

variable "private_subnet_db_cidrs" {
  type = list(string)
}

variable "private_subnet_endpoint_cidrs" {
  type = list(string)
}

variable "app_container_security_group_id" {
  type = string
}
