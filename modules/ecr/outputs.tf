output "backend_repository_url" {
  description = "URL do repositório ECR para backend"
  value       = aws_ecr_repository.backend.repository_url
}

output "backend_repository_arn" {
  description = "ARN do repositório ECR para backend"
  value       = aws_ecr_repository.backend.arn
}

output "nginx_repository_url" {
  description = "URL do repositório ECR para nginx"
  value       = aws_ecr_repository.nginx.repository_url
}

output "nginx_repository_arn" {
  description = "ARN do repositório ECR para nginx"
  value       = aws_ecr_repository.nginx.arn
}
