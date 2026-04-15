# Módulo: iam

Provisiona as roles e permissões IAM necessárias para o funcionamento do cluster ECS.

## Recursos criados

| Recurso | Descrição |
|---|---|
| `aws_iam_role` (ecs_task_execution) | Role assumida pelo ECS para executar tasks (pull de imagem, logs) |
| `aws_iam_role_policy_attachment` (task) | Anexa a policy gerenciada `AmazonECSTaskExecutionRolePolicy` |
| `aws_iam_role_policy` (task ecr) | Policy inline com permissões de pull do ECR e escrita no CloudWatch Logs |
| `aws_iam_role` (ecs_instance) | Role assumida pelas instâncias EC2 do cluster ECS |
| `aws_iam_role_policy_attachment` (instance) | Anexa a policy gerenciada `AmazonEC2ContainerServiceforEC2Role` |
| `aws_iam_role_policy` (instance ecr) | Policy inline com permissões de pull do ECR e escrita no CloudWatch Logs |
| `aws_iam_instance_profile` | Instance profile que vincula a role às instâncias EC2 |

## Propósito

Separa as permissões em dois níveis:
- **Task Execution Role**: usada pelo agente ECS para baixar imagens do ECR e enviar logs ao CloudWatch.
- **Instance Role / Profile**: usada pelas instâncias EC2 para se registrarem no cluster ECS e interagirem com os serviços AWS necessários.

## Variáveis

| Nome | Tipo | Padrão | Descrição |
|---|---|---|---|
| `ecs_task_service_policies` | list(string) | `["AmazonECSTaskExecutionRolePolicy"]` | ARNs de policies gerenciadas para a task execution role |
| `ecs_instance_policies` | list(string) | `["AmazonEC2ContainerServiceforEC2Role"]` | ARNs de policies gerenciadas para a instance role |

## Outputs

| Nome | Descrição |
|---|---|
| `ecs_task_execution_role_arn` | ARN da task execution role (usado na task definition) |
| `ecs_instance_profile_name` | Nome do instance profile (usado no launch template) |
