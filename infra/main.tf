# Configura o provedor da AWS, indicando que vamos criar recursos aqui.
provider "aws" {
  region = "us-east-1" # Você pode escolher a região que preferir, ex: "sa-east-1" para São Paulo
}

# Define o recurso que queremos criar: um repositório ECR.
resource "aws_ecr_repository" "tms_backend_repo" {
  name = "tms-backend"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

# -----------------------------------------------------------------------------
# FONTE DE DADOS: Obtém as Zonas de Disponibilidade (AZs) da região atual.
# -----------------------------------------------------------------------------
data "aws_availability_zones" "available" {}

# -----------------------------------------------------------------------------
# MÓDULO DE REDE (VPC)
# -----------------------------------------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "tms-vpc"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true

  tags = {
    "Project"   = "tms"
    "ManagedBy" = "Terraform"
  }
}

# -----------------------------------------------------------------------------
# GRUPO DE SUB-REDES PARA O RDS
# -----------------------------------------------------------------------------
resource "aws_db_subnet_group" "tms_db_subnet_group" {
  name       = "tms-db-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "TMS DB Subnet Group"
  }
}

# -----------------------------------------------------------------------------
# GRUPO DE SEGURANÇA (FIREWALL) PARA O RDS
# -----------------------------------------------------------------------------
resource "aws_security_group" "tms_db_sg" {
  name        = "tms-db-sg"
  description = "Permite acesso ao banco de dados RDS pela VPC"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tms-db-sg"
  }
}

# -----------------------------------------------------------------------------
# INSTÂNCIA DO BANCO DE DADOS RDS
# -----------------------------------------------------------------------------
resource "aws_db_instance" "tms_database" {
  identifier           = "tms-database"
  instance_class       = "db.t3.micro"
  engine               = "postgres"
  engine_version       = "15" # CORRIGIDO: Usando a versão principal
  port                 = 5432
  allocated_storage    = 20
  db_name              = "tmsdb"
  username             = "postgres"
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.tms_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.tms_db_sg.id]
  skip_final_snapshot  = true
  publicly_accessible  = false
}

# -----------------------------------------------------------------------------
# AWS SECRETS MANAGER
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "tms_db_credentials" {
  name = "tms/db-credentials"
}

resource "aws_secretsmanager_secret_version" "tms_db_credentials_version" {
  secret_id = aws_secretsmanager_secret.tms_db_credentials.id
  secret_string = jsonencode({
    DB_HOST     = aws_db_instance.tms_database.address
    DB_PORT     = aws_db_instance.tms_database.port
    DB_USER     = aws_db_instance.tms_database.username
    DB_PASSWORD = var.db_password
    DB_NAME     = aws_db_instance.tms_database.db_name
  })
}

# -----------------------------------------------------------------------------
# RECURSOS PARA LOGS
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "tms_api_logs" {
  name = "/ecs/tms-api"

  tags = {
    Project = "tms"
  }
}

# -----------------------------------------------------------------------------
# IAM ROLES (CRACHÁS DE PERMISSÃO)
# -----------------------------------------------------------------------------
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "tms-ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "tms-ecs-task-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "secrets_manager_read_policy" {
  name        = "tms-secrets-manager-read-policy"
  description = "Permite que a task do ECS leia o segredo do banco de dados."
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action   = "secretsmanager:GetSecretValue",
        Effect   = "Allow",
        Resource = aws_secretsmanager_secret.tms_db_credentials.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_secrets_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.secrets_manager_read_policy.arn
}

# -----------------------------------------------------------------------------
# ECS CLUSTER
# -----------------------------------------------------------------------------
resource "aws_ecs_cluster" "tms_cluster" {
  name = "tms-cluster"

  tags = {
    Project = "tms"
  }
}

# -----------------------------------------------------------------------------
# APPLICATION LOAD BALANCER (ALB) - A PORTA DE ENTRADA
# -----------------------------------------------------------------------------
resource "aws_alb" "tms_alb" {
  name               = "tms-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.tms_alb_sg.id]
  subnets            = module.vpc.public_subnets

  tags = {
    Project = "tms"
  }
}

resource "aws_alb_target_group" "tms_tg" {
  name        = "tms-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-404"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_alb_listener" "tms_listener" {
  load_balancer_arn = aws_alb.tms_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.tms_tg.arn
  }
}

resource "aws_security_group" "tms_alb_sg" {
  name        = "tms-alb-sg"
  description = "Permite trafego HTTP para o Load Balancer" # CORRIGIDO: Sem acento
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------------------------------------------------------
# ECS - ONDE A APLICAÇÃO RODA
# -----------------------------------------------------------------------------
resource "aws_ecs_task_definition" "tms_api_task" {
  family                   = "tms-api-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "tms-backend"
      image     = "${aws_ecr_repository.tms_backend_repo.repository_url}:latest"
      cpu       = 256
      memory    = 512
      essential = true
      
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]

      secrets = [
        {
          name      = "DB_USER",
          valueFrom = "${aws_secretsmanager_secret.tms_db_credentials.arn}:DB_USER::"
        },
        {
          name      = "DB_PASSWORD",
          valueFrom = "${aws_secretsmanager_secret.tms_db_credentials.arn}:DB_PASSWORD::"
        },
        {
          name      = "DB_HOST",
          valueFrom = "${aws_secretsmanager_secret.tms_db_credentials.arn}:DB_HOST::"
        },
        {
          name      = "DB_PORT",
          valueFrom = "${aws_secretsmanager_secret.tms_db_credentials.arn}:DB_PORT::"
        },
        {
          name      = "DB_NAME",
          valueFrom = "${aws_secretsmanager_secret.tms_db_credentials.arn}:DB_NAME::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.tms_api_logs.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "tms_api_service" {
  name            = "tms-api-service"
  cluster         = aws_ecs_cluster.tms_cluster.id
  task_definition = aws_ecs_task_definition.tms_api_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.tms_ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.tms_tg.arn
    container_name   = "tms-backend"
    container_port   = 8080
  }

  depends_on = [aws_alb_listener.tms_listener]
}

resource "aws_security_group" "tms_ecs_sg" {
  name        = "tms-ecs-sg"
  description = "Permite trafego do Load Balancer para o servico ECS" # CORRIGIDO: Sem acentos
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.tms_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}