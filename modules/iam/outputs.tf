output "ecs_task_execution_role_arn" {
  value = data.aws_iam_role.ecs_task_execution.arn != "" ? data.aws_iam_role.ecs_task_execution.arn : aws_iam_role.ecs_task_execution[0].arn
}

output "ecs_instance_profile_name" {
  value = aws_iam_instance_profile.ecs_ec2.name
}