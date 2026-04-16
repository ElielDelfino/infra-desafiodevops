terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "network" {
  source     = "./modules/network"
  vpc_cidr   = var.vpc_cidr
  azs        = var.azs
  public_subnets_cidr = var.public_subnets_cidr
  private_subnets_cidr = var.private_subnets_cidr
}

module "database" {
  source                = "./modules/database"
  vpc_id                = module.network.vpc_id
  private_subnet_ids    = module.network.private_subnet_ids
  db_name               = var.db_name
  db_username           = var.db_username
  db_password           = var.db_password
  db_instance_type      = var.db_instance_type
  db_allocated_storage  = var.db_allocated_storage
  allowed_cidr_blocks   = [var.vpc_cidr]
}

module "iam" {
  source = "./modules/iam"
  # Adicione as variáveis
}

module "ecr" {
  source   = "./modules/ecr"
  app_name = var.app_name
}

module "compute" {
  source                    = "./modules/compute"
  cluster_name              = var.ecs_cluster_name
  vpc_id                    = module.network.vpc_id
  subnet_ids                = module.network.private_subnet_ids
  public_subnet_ids         = module.network.public_subnet_ids
  task_execution_role_arn   = module.iam.ecs_task_execution_role_arn
  ecs_instance_profile_name = module.iam.ecs_instance_profile_name
  container_image_backend   = module.ecr.backend_repository_url
  container_image_nginx     = module.ecr.nginx_repository_url
  postgres_uri              = "postgres://${var.db_username}:${var.db_password}@${module.database.db_endpoint}/${var.db_name}?sslmode=no-verify"
  jwt_secret                = var.jwt_secret
  initial_image_tag          = var.initial_image_tag
  aws_region                 = var.aws_region
}