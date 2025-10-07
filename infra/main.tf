# Configura o provedor da AWS, indicando que vamos criar recursos aqui.
provider "aws" {
  region = "us-east-1" # Você pode escolher a região que preferir, ex: "sa-east-1" para São Paulo
}

# Define o recurso que queremos criar: um repositório ECR.
resource "aws_ecr_repository" "tms_backend_repo" {
  # O nome que o repositório terá na AWS.
  name = "tms-backend"

  # Permite que a gente sobrescreva tags da imagem, como a "latest".
  # É bom para desenvolvimento.
  image_tag_mutability = "MUTABLE"

  # Habilita o escaneamento de vulnerabilidades automático a cada push.
  # Esta é uma ótima prática de segurança (DevSecOps)!
  image_scanning_configuration {
    scan_on_push = true
  }
}

# -----------------------------------------------------------------------------
# FONTE DE DADOS: Obtém as Zonas de Disponibilidade (AZs) da região atual.
# Isso torna nosso código dinâmico, funcionando em qualquer região sem precisar
# que a gente escreva o nome das AZs (ex: "us-east-1a") manualmente.
# -----------------------------------------------------------------------------
data "aws_availability_zones" "available" {}


# -----------------------------------------------------------------------------
# MÓDULO DE REDE (VPC)
# Aqui, usamos o módulo pré-pronto para criar uma VPC completa.
# -----------------------------------------------------------------------------
module "vpc" {
  # Endereço do módulo no Registro do Terraform.
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  # Nome principal para a VPC e seus componentes.
  name = "tms-vpc"

  # Faixa de IPs principal para toda a nossa rede.
  cidr = "10.0.0.0/16"

  # Lista de Zonas de Disponibilidade que pegamos dinamicamente acima.
  # Vamos usar 2 AZs para ter alta disponibilidade.
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  # Faixas de IPs para as sub-redes PÚBLICAS (onde o Load Balancer ficará).
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  # Faixas de IPs para as sub-redes PRIVADAS (onde a API e o banco de dados ficarão seguros).
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  # Habilita a criação de um NAT Gateway. Isso permite que recursos na sub-rede
  # privada (como nossa API) acessem a internet, mas a internet não consegue acessá-los.
  enable_nat_gateway = true

  # Tags para organizar e identificar nossos recursos na AWS.
  tags = {
    "Project"     = "tms"
    "ManagedBy"   = "Terraform"
  }
}

# -----------------------------------------------------------------------------
# GRUPO DE SUB-REDES PARA O RDS
# Define em quais sub-redes privadas o nosso banco de dados pode ser criado.
# -----------------------------------------------------------------------------
resource "aws_db_subnet_group" "tms_db_subnet_group" {
  name       = "tms-db-subnet-group"
  subnet_ids = module.vpc.private_subnets # Pega as IDs das sub-redes privadas do módulo VPC

  tags = {
    Name = "TMS DB Subnet Group"
  }
}

# -----------------------------------------------------------------------------
# GRUPO DE SEGURANÇA (FIREWALL) PARA O RDS
# Controla quem pode acessar o banco de dados.
# -----------------------------------------------------------------------------
resource "aws_security_group" "tms_db_sg" {
  name        = "tms-db-sg"
  description = "Permite acesso ao banco de dados RDS pela VPC"
  vpc_id      = module.vpc.vpc_id # Associa este firewall à nossa VPC

  # Regra de entrada: permite tráfego na porta 5432 (PostgreSQL)
  # vindo de qualquer lugar de DENTRO da nossa VPC.
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block] # Acesso liberado apenas para a própria rede
  }

  # Regra de saída: permite que o banco de dados se conecte a qualquer lugar.
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
# Finalmente, o nosso banco de dados PostgreSQL.
# -----------------------------------------------------------------------------
resource "aws_db_instance" "tms_database" {
  identifier          = "tms-database"
  instance_class      = "db.t3.micro"       # Classe de instância elegível no Free Tier da AWS
  engine              = "postgres"
  engine_version      = "15.14"
  port                = 5432
  allocated_storage   = 20                  # 20 GB de armazenamento
  
  db_name             = "tmsdb"             # Nome inicial do banco de dados
  username            = "postgres"
  password            = var.db_password     # Pega a senha da nossa variável segura

  db_subnet_group_name = aws_db_subnet_group.tms_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.tms_db_sg.id]

  skip_final_snapshot = true # Em produção, isso seria 'false'
  publicly_accessible = false # MUITO IMPORTANTE: Garante que o banco não seja acessível pela internet
}