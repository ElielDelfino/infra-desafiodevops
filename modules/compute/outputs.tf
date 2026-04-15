output "ecs_cluster_id" {
  value = aws_ecs_cluster.this.id
}

output "ecs_service_name" {
  value = aws_ecs_service.app.name
}

output "ecs_task_definition_arn" {
  value = aws_ecs_task_definition.app.arn
}

# DNS público do ALB — use este endereço para acessar a API
output "alb_dns_name" {
  value = aws_lb.this.dns_name
}
