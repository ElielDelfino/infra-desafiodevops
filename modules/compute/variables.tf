variable "cluster_name" {
  description = "Nome do ECS Cluster"
  type        = string
}

variable "ecs_instance_type" {
  description = "Tipo da EC2 para ECS"
  type        = string
  default     = "t3.micro"
}

variable "subnet_ids" {
  description = "Subnets privadas para ECS instances"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC para os recursos ECS"
  type        = string
}

variable "desired_capacity" {
  type        = number
  default     = 2
}

variable "max_size" {
  type        = number
  default     = 4
}

variable "min_size" {
  type        = number
  default     = 2
}

variable "task_execution_role_arn" {
  description = "ARN da role de execução do ECS Task"
  type        = string
}

variable "ecs_instance_profile_name" {
  description = "Nome do IAM Instance Profile para ECS EC2"
  type        = string
}

variable "container_image_backend" {
  description = "URL da imagem backend do ECR"
  type        = string
}

variable "container_image_nginx" {
  description = "URL da imagem nginx do ECR"
  type        = string
}

variable "container_port_backend" {
  description = "Porta container backend"
  type        = number
  default     = 8000
}

variable "container_port_nginx" {
  description = "Porta container Nginx"
  type        = number
  default     = 80
}

variable "postgres_uri" {
  description = "URI de conexão PostgreSQL para o backend"
  type        = string
}

variable "jwt_secret" {
  description = "JWT secret para o backend"
  type        = string
  sensitive   = true
}

# Subnets públicas onde o ALB será criado (precisa de 2 AZs)
variable "public_subnet_ids" {
  description = "Subnets públicas para o ALB"
  type        = list(string)
}
# Usada apenas no primeiro apply. Após isso, o workflow controla a tag via task definition.
variable "initial_image_tag" {
  type        = string
  description = "Tag inicial das imagens (ex: latest). Deployments posteriores usam o SHA do commit."
}

variable "aws_region" {
  type    = string
  description = "Região AWS"
}