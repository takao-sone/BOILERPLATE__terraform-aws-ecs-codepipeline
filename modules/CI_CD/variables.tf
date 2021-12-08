# Base ========================
variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

# ========================
variable "app_ecs_service_name" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "alb_http_listener_arn" {
  type = string
}

variable "alb_http_test_listener_arn" {
  type = string
}

variable "alb_blue_target_group_name" {
  type = string
}

variable "alb_green_target_group_name" {
  type = string
}

variable "github_account_name" {
  type = string
}

variable "github_repository_name" {
  type = string
}

# SSM Parameter
variable "docker_hub_username" {
  type = string
}

variable "docker_hub_password" {
  type = string
}
