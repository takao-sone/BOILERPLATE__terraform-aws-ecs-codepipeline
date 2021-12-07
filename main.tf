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

resource "aws_resourcegroups_group" "resource_group" {
  name     = "${var.project_name}-resource-group"

  resource_query {
    query = jsonencode(
    {
      ResourceTypeFilters = [
        "AWS::AllSupported",
      ]
      TagFilters          = [
        {
          Key    = "Project"
          Values = [
            var.project_name,
          ]
        },
      ]
    }
    )
    type  = "TAG_FILTERS_1_0"
  }

  tags     = {
    Name     = "${var.project_name}-resource-group"
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
  app_container_security_group_id = module.ecs.app_container_security_group_id
}

module "alb" {
  source            = "./modules/ALB"
  project_name      = var.project_name
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
}

module "iam" {
  source       = "./modules/IAM"
  project_name = var.project_name
}

module "ecs" {
  source                             = "./modules/ECS"
  project_name                       = var.project_name
  aws_region                         = var.aws_region
  vpc_id                             = module.networking.vpc_id
  app_container_name                 = "${var.project_name}-container"
  ecs_log_group_name                 = "/ecs/${var.project_name}-ecs-log-group"
  app_service_subnet_ids             = module.networking.private_subnet_container_ids
  alb_security_group_id              = module.alb.alb_security_group_id
  app_service_blue_target_group_arn  = module.alb.app_service_blue_target_group_arn
  app_service_green_target_group_arn = module.alb.app_service_green_target_group_arn
}