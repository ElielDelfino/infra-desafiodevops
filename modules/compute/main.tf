# ECS Cluster
resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
}

data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

# Security Group do ALB
# Permite tráfego HTTP da internet. As EC2 só aceitam tráfego vindo deste SG.
resource "aws_security_group" "alb" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Security group do ALB - permite HTTP da internet"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.cluster_name}-alb-sg" }
}

# Security Group das instâncias ECS
# Porta 80 liberada apenas para o ALB (não mais para a internet diretamente).
resource "aws_security_group" "ecs" {
  name        = "${var.cluster_name}-ecs-sg"
  description = "Security group for ECS instances"
  vpc_id      = var.vpc_id

  # Porta 80 aceita somente do ALB, não da internet diretamente
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.cluster_name}-ecs-sg" }
}

# Application Load Balancer
# Fica nas subnets públicas para receber tráfego da internet.
resource "aws_lb" "this" {
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = { Name = "${var.cluster_name}-alb" }
}

# Target Group
# Define como o ALB verifica a saúde das instâncias EC2.
# O ALB envia tráfego apenas para instâncias saudáveis.
resource "aws_lb_target_group" "this" {
  name     = "${var.cluster_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  # Reduz o tempo de draining para acelerar deployments
  deregistration_delay = 30

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200-499"
  }

  tags = { Name = "${var.cluster_name}-tg" }
}

# Listener do ALB
# Escuta na porta 80 e encaminha todas as requisições para o target group.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# Launch Template das instâncias ECS
resource "aws_launch_template" "ecs" {
  name_prefix   = "${var.cluster_name}-lt-"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = var.ecs_instance_type

  network_interfaces {
    security_groups             = [aws_security_group.ecs.id]
  }

  iam_instance_profile {
    name = var.ecs_instance_profile_name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    cluster_name = var.cluster_name
  }))
}

# Auto Scaling Group
# Associado ao target group do ALB para que as instâncias sejam
# registradas/desregistradas automaticamente conforme sobem ou descem.
resource "aws_autoscaling_group" "ecs" {
  name                 = "${var.cluster_name}-asg"
  min_size             = var.min_size
  max_size             = var.max_size
  desired_capacity     = var.desired_capacity
  vpc_zone_identifier  = var.subnet_ids

  # Associa o ASG ao target group do ALB
  target_group_arns = [aws_lb_target_group.this.arn]

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-ecs"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity, min_size, max_size]
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 60
    }
  }
}

# Task Definition (multi-container: Nginx + Backend)
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.cluster_name}-app"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  cpu                      = "384"
  memory                   = "640"
  execution_role_arn       = var.task_execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "${var.container_image_backend}:${var.image_tag}"
      cpu       = 192
      memory    = 384
      # hostPort fixo para que o nginx consiga alcançar o backend via 172.17.0.1
      portMappings = [{ containerPort = var.container_port_backend, hostPort = var.container_port_backend }]
      essential = true
      environment = [
        { name = "NODE_ENV",               value = "production" },
        { name = "PORT",                   value = tostring(var.container_port_backend) },
        { name = "POSTGRES_URI",           value = var.postgres_uri },
        { name = "JWT_SECRET",             value = var.jwt_secret },
        { name = "GCS_PUBLIC_BUCKET_NAME", value = "placeholder" },
        { name = "GCS_PRIVATE_BUCKET_NAME", value = "placeholder" },
        { name = "GCS_PROJECT_ID",         value = "placeholder" },
        { name = "GCS_CREDENTIALS",        value = "{}" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.cluster_name}/backend"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
          "awslogs-create-group"  = "true"
        }
      }
    },
    {
      name      = "nginx"
      image     = "${var.container_image_nginx}:${var.image_tag}"
      cpu       = 128
      memory    = 192
      # hostPort 80 é a porta que o ALB vai bater no health check e encaminhar tráfego
      portMappings = [{ containerPort = var.container_port_nginx, hostPort = 80 }]
      essential = true
      dependsOn = [{ containerName = "backend", condition = "START" }]
    }
  ])
}

# ECS Service
# load_balancer: registra o container nginx no target group do ALB.
# O ALB passa a fazer health check diretamente no container nginx de cada instância.
resource "aws_ecs_service" "app" {
  name            = "${var.cluster_name}-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2

  deployment_controller {
    type = "ECS"
  }
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "EC2"

  # Grace period para a API ter tempo de inicializar antes do ALB checar saúde
  health_check_grace_period_seconds = 120

  # Associa o serviço ao ALB via target group
  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "nginx"
    container_port   = var.container_port_nginx
  }

  # Ignorar mudanças de task_definition para nao reverter deploys feitos pelo workflow do app 
  lifecycle{
    ignore_changes = [task_definition]
  }

  depends_on = [
    aws_autoscaling_group.ecs,
    aws_lb_listener.http
  ]
}
