# Módulo: compute

Provisiona toda a camada de computação da aplicação: cluster ECS (EC2 launch type), Auto Scaling Group, Application Load Balancer e o serviço com dois containers (backend + Nginx).

## Recursos criados

| Recurso | Descrição |
|---|---|
| `aws_ecs_cluster` | Cluster ECS que agrupa os serviços e tasks |
| `aws_security_group` (alb) | SG do ALB — libera porta 80 da internet |
| `aws_security_group` (ecs) | SG das instâncias EC2 — porta 80 aceita somente do ALB |
| `aws_lb` | Application Load Balancer público nas subnets públicas |
| `aws_lb_target_group` | Target group com health check em `/` (HTTP 200-499) |
| `aws_lb_listener` | Listener HTTP na porta 80 encaminhando para o target group |
| `aws_launch_template` | Template das instâncias EC2 com AMI ECS-optimized e user data |
| `aws_autoscaling_group` | ASG com rolling update, min/max/desired configuráveis |
| `aws_ecs_task_definition` | Task definition multi-container: `backend` (porta 8000) + `nginx` (porta 80) |
| `aws_ecs_service` | Serviço ECS com 2 tasks desejadas, integrado ao ALB |

## Arquitetura

```
Internet → ALB (subnets públicas) → Target Group → Nginx container (porta 80)
                                                         ↓
                                                  Backend container (porta 8000)
                                                         ↓
                                                  RDS PostgreSQL (subnet privada)
```

- O ALB fica nas subnets **públicas** e recebe tráfego da internet.
- As instâncias EC2 ficam nas subnets **privadas** e só aceitam tráfego do ALB.
- O container Nginx atua como proxy reverso para o backend.
- O `hostPort` do backend é fixo (`8000`) para que o Nginx consiga alcançá-lo via `172.17.0.1`.
- O `user_data.sh.tpl` registra a instância no cluster ECS ao inicializar.

## Variáveis principais

| Nome | Padrão | Descrição |
|---|---|---|
| `cluster_name` | — | Nome do cluster ECS |
| `vpc_id` | — | ID da VPC |
| `subnet_ids` | — | Subnets privadas para as instâncias EC2 |
| `public_subnet_ids` | — | Subnets públicas para o ALB |
| `ecs_instance_type` | `t3.micro` | Tipo da instância EC2 |
| `desired_capacity` | `2` | Número desejado de instâncias |
| `min_size` / `max_size` | `2` / `4` | Limites do ASG |
| `container_port_backend` | `8000` | Porta do container backend |
| `container_port_nginx` | `80` | Porta do container Nginx |
| `task_execution_role_arn` | — | ARN da task execution role (módulo iam) |
| `ecs_instance_profile_name` | — | Nome do instance profile (módulo iam) |
| `container_image_backend` | — | URL da imagem backend no ECR |
| `container_image_nginx` | — | URL da imagem Nginx no ECR |
| `image_tag` | — | Tag da imagem (ex: git SHA) |
| `postgres_uri` | — | URI de conexão com o PostgreSQL |
| `jwt_secret` | — | Secret JWT para o backend |
| `aws_region` | — | Região AWS para configuração de logs |

## Outputs

| Nome | Descrição |
|---|---|
| `ecs_cluster_id` | ID do cluster ECS |
| `ecs_service_name` | Nome do serviço ECS |
| `ecs_task_definition_arn` | ARN da task definition |
| `alb_dns_name` | DNS público do ALB para acesso à API |
