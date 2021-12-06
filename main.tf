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

module "networking" {
  source                         = "./modules/Networking"
  project_name                   = var.project_name
  aws_region                     = var.aws_region
  vpc_cidr                       = var.vpc_cidr
  public_subnet_cidrs            = var.public_subnet_cidrs
  private_subnet_endpoint_cidrs  = var.private_subnet_endpoint_cidrs
  private_subnet_container_cidrs = var.private_subnet_container_cidrs
  private_subnet_db_cidrs        = var.private_subnet_db_cidrs
  alb_sg_id                      = module.alb.alb_sg_id
}

module "alb" {
  source       = "./modules/ALB"
  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
}

module "iam" {
  source = "./modules/IAM"
  project_name = var.project_name
}