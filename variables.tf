variable "aws_region"         { type = string }
variable "vpc_cidr"           { type = string }
variable "azs"                { type = list(string) }
variable "public_subnets_cidr" { type = list(string) }
variable "private_subnets_cidr" { type = list(string) }
variable "db_name"            { type = string }
variable "db_username"        { type = string }
variable "db_password"        { type = string }
variable "db_instance_type"   { type = string }
variable "db_allocated_storage" { type = number }
variable "ecs_cluster_name"   { type = string }
variable "app_name"           { type = string }
variable "jwt_secret" {
  type      = string
  sensitive = true
  default   = "change-me-in-production"
}
variable "image_tag" { type = string }
