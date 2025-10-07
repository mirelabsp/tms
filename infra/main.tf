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