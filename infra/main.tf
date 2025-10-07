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