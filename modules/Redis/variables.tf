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

# ========================
variable "private_redis_subnet_ids" {
  type = list(string)
}

variable "app_container_security_group_id" {
  type = string
}
