# Role de execução das tasks ECS (pull de imagem, logs)
resource "aws_iam_role" "ecs_task_execution" {
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

# Anexa a policy gerenciada da AWS para execução de tasks ECS
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  count      = length(var.ecs_task_service_policies)
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = var.ecs_task_service_policies[count.index]
}

# Permissões adicionais: pull do ECR e escrita de logs no CloudWatch
resource "aws_iam_role_policy" "ecs_task_execution_ecr" {
  name   = "ecs-task-execution-ecr-policy"
  role   = aws_iam_role.ecs_task_execution.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
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
    }]
  })
}

# Role das instâncias EC2 que compõem o cluster ECS
resource "aws_iam_role" "ecs_instance" {
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

# Anexa a policy gerenciada da AWS para instâncias no cluster ECS
resource "aws_iam_role_policy_attachment" "ecs_instance" {
  count      = length(var.ecs_instance_policies)
  role       = aws_iam_role.ecs_instance.name
  policy_arn = var.ecs_instance_policies[count.index]
}

# Permissões adicionais: pull do ECR e escrita de logs no CloudWatch
resource "aws_iam_role_policy" "ecs_instance_ecr" {
  name   = "ecs-instance-ecr-policy"
  role   = aws_iam_role.ecs_instance.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:GetAuthorizationToken",
        "ecr:DescribeImages",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "*"
    }]
  })
}

# Instance profile vincula a role à instância EC2
resource "aws_iam_instance_profile" "ecs_ec2" {
  name = "ecsInstanceProfile"
  role = aws_iam_role.ecs_instance.name
}