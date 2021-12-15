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

variable "ecs_migration_task_log_group_name" {
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

# SSM Parameter
variable "ssm_param_app_bound_address" {
  type = string
}

variable "ssm_param_app_frontend_origin" {
  type = string
}

variable "ssm_param_app_valid_origin_value" {
  type = string
}

variable "ssm_param_app_valid_referer_value" {
  type = string
}

variable "ssm_param_app_database_url" {
  type = string
}

variable "ssm_param_app_redis_address_port" {
  type = string
}

variable "ssm_param_app_redis_private_key" {
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
