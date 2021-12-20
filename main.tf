provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region

  default_tags {
    tags = {
      Created_by = "Terraform"
      Project    = var.project_name
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_resourcegroups_group" "resource_group" {
  name = "${var.project_name}-resource-group"

  resource_query {
    query = jsonencode(
      {
        ResourceTypeFilters = [
          "AWS::AllSupported",
        ]
        TagFilters = [
          {
            Key = "Project"
            Values = [
              var.project_name,
            ]
          },
        ]
      }
    )
    type = "TAG_FILTERS_1_0"
  }

  tags = {
    Name = "${var.project_name}-resource-group"
  }
}

module "networking" {
  source                          = "./modules/Networking"
  project_name                    = var.project_name
  aws_region                      = var.aws_region
  vpc_cidr                        = var.vpc_cidr
  public_subnet_cidrs             = var.public_subnet_cidrs
  private_subnet_endpoint_cidrs   = var.private_subnet_endpoint_cidrs
  private_subnet_container_cidrs  = var.private_subnet_container_cidrs
  private_subnet_db_cidrs         = var.private_subnet_db_cidrs
  private_subnet_redis_cidrs      = var.private_subnet_redis_cidrs
  app_container_security_group_id = module.ecs.app_container_security_group_id
}

module "alb" {
  source            = "./modules/ALB"
  project_name      = var.project_name
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  health_check_path = "/api/v1/"
}

module "ecs" {
  source                             = "./modules/ECS"
  project_name                       = var.project_name
  aws_region                         = var.aws_region
  vpc_id                             = module.networking.vpc_id
  app_container_name                 = "${var.project_name}-container"
  ecs_log_group_name                 = "/ecs/${var.project_name}-ecs-log-group"
  ecs_migration_task_log_group_name  = "/ecs/${var.project_name}-ecs-migration-log-group"
  app_service_subnet_ids             = module.networking.private_subnet_container_ids
  alb_security_group_id              = module.alb.alb_security_group_id
  app_service_blue_target_group_arn  = module.alb.app_service_blue_target_group_arn
  app_service_green_target_group_arn = module.alb.app_service_green_target_group_arn
  # SSM Parameter
  ssm_param_app_bound_address       = var.ssm_param_app_bound_address
  ssm_param_app_database_url        = module.db.postgres_rds_url
  ssm_param_app_frontend_origin     = var.ssm_param_app_frontend_origin
  ssm_param_app_redis_address_port  = module.redis.cache_node_address_primary_endpoint
  ssm_param_app_redis_private_key   = var.ssm_param_app_redis_private_key
  ssm_param_app_valid_origin_value  = var.ssm_param_app_valid_origin_value
  ssm_param_app_valid_referer_value = var.ssm_param_app_valid_referer_value
  ssm_param_app_rust_log            = var.ssm_param_app_rust_log
  ssm_param_app_rust_backtrace      = var.ssm_param_app_rust_backtrace
}

module "ci_cd" {
  source                      = "./modules/CI_CD"
  aws_region                  = var.aws_region
  project_name                = var.project_name
  account_id                  = data.aws_caller_identity.current.account_id
  alb_blue_target_group_name  = module.alb.alb_blue_target_group_name
  alb_green_target_group_name = module.alb.alb_green_target_group_name
  alb_http_listener_arn       = module.alb.alb_http_listener_arn
  alb_http_test_listener_arn  = module.alb.alb_http_test_listener_arn
  ecs_cluster_name            = module.ecs.ecs_cluster_name
  app_ecs_service_name        = module.ecs.app_ecs_service_name
  github_account_name         = var.github_account_name
  github_repository_name      = var.github_repository_name
  # SSM Parameter
  #  docker_hub_username         = var.docker_hub_username
  #  docker_hub_password         = var.docker_hub_password
}

module "db" {
  source                 = "./modules/DB"
  project_name           = var.project_name
  vpc_id                 = module.networking.vpc_id
  app_container_sg_id    = module.ecs.app_container_security_group_id
  private_rds_subnet_ids = module.networking.private_subnet_db_ids
  rds_master_password    = "${replace(var.project_name, "-", "")}${var.rds_master_username}"
  rds_master_username    = "${replace(var.project_name, "-", "")}${var.rds_master_password}"
}

module "redis" {
  source                          = "./modules/Redis"
  project_name                    = var.project_name
  vpc_id                          = module.networking.vpc_id
  app_container_security_group_id = module.ecs.app_container_security_group_id
  private_redis_subnet_ids        = module.networking.private_subnet_redis_ids
}