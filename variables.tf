# Base ========================
variable "project_name" {
  type = string
}

variable "aws_profile" {
  type = string
}

variable "aws_region" {
  type = string
}

# Networking ===========================
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
