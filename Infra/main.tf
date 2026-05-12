provider "aws" {
  region = "us-east-1"
}

# VPC
# =========================================================

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# SUBNETS
# =========================================================
#Subnets publicas acessíveis pela internet = ALB - NAT Gateway
# =========================================================
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}
#Subnets privadas - sem acesso direto da internet = ECS - RDS
# =========================================================
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1b"
}

# INTERNET + NAT
# =========================================================
#Conecta a VPC à internet.
# =========================================================
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_eip" "nat" {}

#Permite saída para internet das subnets privadas
# =========================================================
resource "aws_nat_gateway" "nat" {
  subnet_id     = aws_subnet.public_a.id
  allocation_id = aws_eip.nat.id
}

# ROUTES
# =========================================================

# PUBLIC
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# PRIVATE
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

# ASSOCIATIONS
resource "aws_route_table_association" "pub_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "pub_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "priv_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "priv_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_rt.id
}

# SECURITY GROUPS
# =========================================================
# Balaceador de carga - ALB
# =========================================================
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main.id

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
}

# ECS = ECS acessível somente para aplicação 
# =========================================================
resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS = O banco não é acessível pela internet.
# =========================================================
resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }
}
# RDS (PRIVADO)
# =========================================================

resource "aws_db_subnet_group" "db_subnet" {
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]
}

resource "aws_db_instance" "postgres123" {
  engine            = "postgres"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  username          = "postgres"
  password          = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  publicly_accessible = false
  skip_final_snapshot = true
}
# ALB = Distribui tráfego entre containers ECS
# =========================================================

resource "aws_lb" "alb" {
  load_balancer_type = "application"
  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
  security_groups = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "tg" {
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path = "/health"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# ECS CLuster = onde os containers serão executados
# =========================================================
resource "aws_ecs_cluster" "cluster" {
  name = "simple_api"
}
#Configuracoes do container 
# =========================================================
resource "aws_ecs_task_definition" "task" {
  family                   = "api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = 256
  memory = 512

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "api"
      image = "060651978771.dkr.ecr.us-east-1.amazonaws.com/simple-api:latest"

      essential = true

      portMappings = [
        {
          containerPort = 3000
        }
      ]

      environment = [
        {
          name  = "DB_HOST"
          value = aws_db_instance.postgres123.address
        }
      ]
# Configuração de logs do container no CloudWatch Logs
# =========================================================
      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}
# Grupo de logs do CloudWatch utilizado pelo ECS
# =========================================================
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/simple-api"
  retention_in_days = 7
}
#Alta disponibilidade - ECS recria automaticamente
# =========================================================
resource "aws_ecs_service" "service" {
  name            = "api-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets = [
      aws_subnet.private_a.id,
      aws_subnet.private_b.id
    ]

    security_groups = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "api"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.listener]
}
#IAM Role = puxar imagem ECR - enviar logs CloudWatch - acessar serviços AWS
# =========================================================
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
# OUTPUTS - INFRA AWS (ALB / ECS / RDS)
# =========================================================

# URL pública da aplicação
output "alb_dns" {
  description = "DNS público do Application Load Balancer"
  value       = aws_lb.alb.dns_name
}

# Endpoint do banco PostgreSQL
output "rds_endpoint" {
  description = "Endpoint do RDS PostgreSQL"
  value       = aws_db_instance.postgres123.address
}

# Porta do banco
output "rds_port" {
  description = "Porta do RDS PostgreSQL"
  value       = aws_db_instance.postgres123.port
}

# Nome do cluster ECS
output "ecs_cluster_name" {
  description = "Nome do cluster ECS"
  value       = aws_ecs_cluster.cluster.name
}

# ARN do cluster ECS
output "ecs_cluster_arn" {
  description = "ARN do cluster ECS"
  value       = aws_ecs_cluster.cluster.arn
}