variable "ecs_task_service_policies" {
  description = "Policies ARNs to attach to ECS task execution role"
  type        = list(string)
  default     = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
}

variable "ecs_instance_policies" {
  description = "Policies ARNs to attach to ECS EC2 instance profile"
  type        = list(string)
  default     = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  ]
}