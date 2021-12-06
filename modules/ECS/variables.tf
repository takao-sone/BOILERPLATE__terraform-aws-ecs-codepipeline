# Base ========================
variable "project_name" {
  type = string

  validation {
    # regex(...) fails if it cannot find a match
    condition     = can(regex("^[a-z0-9_-]*$", var.project_name))
    error_message = "For the project_name value only a-z, 0-9, _ and - are allowed."
  }
}

variable "vpc_id" {
  type = string
}

variable "aws_region" {
  type = string
}

# ========================
variable "app_container_name" {
  type = string
}

variable "ecs_log_group_name" {
  type = string
}

# Service
variable "app_service_subnet_ids" {
  type = list(string)
}

variable "alb_security_group_id" {
  type = string
}

variable "app_service_blue_target_group_arn" {
  type = string
}

variable "app_service_green_target_group_arn" {
  type = string
}

# Task
#variable "app_ecs_task_execution_role_arn" {
#  type = string
#}
#
#variable "app_ecs_task_role_arn" {
#  type = string
#}
