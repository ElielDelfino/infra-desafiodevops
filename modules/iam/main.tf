# Execution Role (ECS Tasks) - Usar role existente se já criada
data "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole"
}

# Se a role não existir, criar uma nova
resource "aws_iam_role" "ecs_task_execution" {
  count              = data.aws_iam_role.ecs_task_execution.id == "" ? 1 : 0
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_task.json
}

data "aws_iam_policy_document" "assume_role_policy_task" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

locals {
  ecs_task_execution_role_name = data.aws_iam_role.ecs_task_execution.id != "" ? data.aws_iam_role.ecs_task_execution.name : aws_iam_role.ecs_task_execution[0].name
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  count      = length(var.ecs_task_service_policies)
  role       = local.ecs_task_execution_role_name
  policy_arn = var.ecs_task_service_policies[count.index]
}

# Task Execution Role - ECR Pull Permissions
resource "aws_iam_role_policy" "ecs_task_execution_ecr" {
  name   = "ecs-task-execution-ecr-policy"
  role   = local.ecs_task_execution_role_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# EC2 Instance Profile (ECS cluster nodes) - Usar role existente se já criada
data "aws_iam_role" "ecs_instance" {
  name = "ecsInstanceRole"
}

# Se a role não existir, criar uma nova
resource "aws_iam_role" "ecs_instance" {
  count              = data.aws_iam_role.ecs_instance.id == "" ? 1 : 0
  name               = "ecsInstanceRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_instance.json
}

data "aws_iam_policy_document" "assume_role_policy_instance" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

locals {
  ecs_instance_role_name = data.aws_iam_role.ecs_instance.id != "" ? data.aws_iam_role.ecs_instance.name : aws_iam_role.ecs_instance[0].name
}

resource "aws_iam_role_policy_attachment" "ecs_instance" {
  count      = length(var.ecs_instance_policies)
  role       = local.ecs_instance_role_name
  policy_arn = var.ecs_instance_policies[count.index]
}

# EC2 Instance Role - ECR Pull Permissions
resource "aws_iam_role_policy" "ecs_instance_ecr" {
  name   = "ecs-instance-ecr-policy"
  role   = local.ecs_instance_role_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken",
          "ecr:DescribeImages"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ecs_ec2" {
  name = "ecsInstanceProfile"
  role = local.ecs_instance_role_name
}