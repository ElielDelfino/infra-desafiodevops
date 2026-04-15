output "vpc_id" {
  value = module.network.vpc_id
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "rds_endpoint" {
  value = module.database.db_endpoint
  sensitive = true
}

output "ecs_cluster_id" {
  value = module.compute.ecs_cluster_id
}

output "ecs_service_name" {
  value = module.compute.ecs_service_name
}

output "alb_dns_name" {
  description = "DNS do ALB - use este endereço para acessar a API"
  value       = module.compute.alb_dns_name
}

output "ecr_backend_repository_url" {
  description = "URL do repositório ECR para backend"
  value       = module.ecr.backend_repository_url
}

output "ecr_nginx_repository_url" {
  description = "URL do repositório ECR para nginx"
  value       = module.ecr.nginx_repository_url
}