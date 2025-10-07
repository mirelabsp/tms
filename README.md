-----

# 🚛 TMS — Transport Management System

Projeto **Full-Stack** de um Sistema de Gestão de Transportes (TMS) com deploy automatizado na nuvem da AWS. A aplicação foi desenvolvida com foco em boas práticas de DevOps, utilizando Infraestrutura como Código (IaC) com Terraform e um pipeline de Integração e Deploy Contínuo (CI/CD) com GitHub Actions.

O backend é uma API REST construída com Python/FastAPI e o frontend é uma interface reativa desenvolvida com React.

## ☁️ Arquitetura na AWS

A aplicação roda em uma arquitetura serverless e escalável na AWS, totalmente provisionada via Terraform:

  * **Pipeline CI/CD:** O **GitHub Actions** é responsável por construir a imagem Docker da aplicação e publicá-la no ECR a cada `push` na branch `main`.
  * **Frontend:** A aplicação React é hospedada como um site estático em um bucket **S3**, com distribuição global e HTTPS através do **CloudFront (CDN)**.
  * **Backend:** A API REST em Python/FastAPI roda como um contêiner no **ECS Fargate**, uma tecnologia serverless que gerencia a execução e escalabilidade da aplicação sem a necessidade de provisionar servidores.
  * **Roteamento e Acesso:** Um **Application Load Balancer (ALB)** recebe o tráfego da internet e o distribui de forma segura para os contêineres da aplicação, que rodam em uma rede privada.
  * **Dados e Persistência:** Um banco de dados **PostgreSQL**, rodando no serviço gerenciado **RDS**, armazena todos os dados da aplicação em uma sub-rede privada e segura.
  * **Segurança:** As credenciais do banco de dados são armazenadas de forma segura no **AWS Secrets Manager**, e as permissões de acesso são rigorosamente controladas através de políticas no **IAM**.
  * **Rede:** Toda a infraestrutura reside em uma **VPC** customizada, com sub-redes públicas para recursos expostos à internet (como o ALB) e sub-redes privadas para proteger o backend e o banco de dados.

## 🧩 Funcionalidades

| Recurso | Backend (API) | Frontend |
| :--- | :---: | :---: |
| 🚗 **Veículos** | ✅ CRUD Completo | ✅ Listagem |
| 👷 **Motoristas** | ✅ CRUD Completo | 🚧 Em desenvolvimento |
| 🗺️ **Rotas** | ✅ CRUD Completo | 🚧 Em desenvolvimento |
| 📦 **Entregas** | ✅ CRUD Completo | 🚧 Em desenvolvimento |

## ⚙️ Tecnologias Utilizadas

#### Backend

  * Python 3.11
  * FastAPI
  * SQLModel (ORM)

#### Frontend

  * React
  * Vite
  * Axios

#### Infraestrutura & DevOps (IaC & CI/CD)

  * Terraform
  * Docker & Docker Compose
  * GitHub Actions

#### Cloud (AWS)

  * **Computação:** ECS Fargate
  * **Rede:** VPC, Application Load Balancer (ALB), Route 53
  * **Armazenamento:** RDS (PostgreSQL), S3, ECR
  * **Segurança:** IAM, Secrets Manager, ACM (Certificate Manager)
  * **Monitoramento:** CloudWatch

## 🧱 Estrutura do Projeto

```
tms/
├─ .github/workflows/      # Pipeline de CI/CD com GitHub Actions
│  └─ ci.yml
├─ backend/                # Código da API em Python/FastAPI
│  ├─ main.py
│  ├─ Dockerfile
│  └─ ...
├─ frontend/               # Código da interface em React
│  ├─ src/
│  └─ ...
├─ infra/                  # Código da Infraestrutura (Terraform)
│  ├─ main.tf
│  └─ variables.tf
├─ docker-compose.yml      # Orquestra os containers para ambiente local
└─ README.md
```

## 🚀 Como Executar o Projeto

### Rodando Localmente

O ambiente local simula a arquitetura da nuvem usando Docker Compose.

**1. Subir o Backend e o Banco de Dados:**

```bash
# Na pasta raiz do projeto (tms/)
docker compose up --build
```

  * A API estará disponível em: `http://localhost:8080`
  * A documentação interativa (Swagger) em: `http://localhost:8080/docs`

**2. Subir o Frontend:**

```bash
# Em outro terminal, navegue até a pasta do frontend
cd tms-frontend

# Instale as dependências (apenas na primeira vez)
npm install

# Inicie o servidor de desenvolvimento
npm run dev
```

  * O frontend estará disponível em: `http://localhost:5173` (ou a porta indicada no terminal)

### Deploy na AWS

Toda a infraestrutura é gerenciada pelo Terraform na pasta `infra/`. O deploy da aplicação é automatizado: um `git push` para a branch `main` ativa o pipeline do GitHub Actions, que constrói e publica a nova imagem da API no ECR. O serviço ECS pode então ser atualizado para usar a nova imagem.

## 📅 Roadmap do Projeto

### ✅ Fase 1: API e Ambiente Local

  - [x] CRUD de Veículos (Create, Read, Update, Delete)
  - [x] CRUD de Motoristas
  - [x] CRUD de Rotas e Entregas
  - [x] Conteinerização da API com Docker

### ✅ Fase 2: Infraestrutura na AWS e CI/CD

  - [x] **CI/CD com GitHub Actions:** Pipeline que constrói e envia a imagem para o ECR.
  - [x] **Infraestrutura como Código (Terraform):**
      - [x] Rede segura (VPC com sub-redes públicas e privadas)
      - [x] Banco de dados gerenciado (Integração com AWS RDS)
      - [x] Registro de contêiner privado (ECR)
      - [x] Gerenciamento de segredos (Secrets Manager)
  - [x] **Deploy da API na AWS ECS:**
      - [x] Configuração do Cluster, Task Definition e Service
      - [x] Publicação da API na internet via Application Load Balancer

### 🚧 Fase 3: Frontend e UI

  - [x] **Estrutura do Frontend:** Projeto React criado e rodando localmente.
  - [x] **Integração com Backend:** Frontend consumindo dados da API na AWS.
  - [ ] Criação das telas de Motoristas, Rotas e Entregas.
  - [ ] Implementação de formulários para Criar e Editar dados.
  - [ ] Deploy do Frontend na AWS (S3 + CloudFront).

### ⏳ Próximos Passos e Melhorias

  - [ ] **Monitoramento com CloudWatch:** Criar dashboards e alarmes para a saúde da aplicação.
  - [ ] **Segurança HTTPS:** Adicionar certificado SSL no Load Balancer.
  - [ ] **Domínio Personalizado:** Configurar um domínio próprio com Route 53.
  - [ ] **Testes Automatizados:** Adicionar `pytest` ao pipeline de CI/CD para garantir a qualidade do código.
  - [ ] **Autenticação de Usuários:** Implementar login na API e no frontend.

## 👩‍💻 Autoria

Desenvolvido por **Mirela Santana** 💜

Foco em DevOps | Cloud | Backend Python

📦 GitHub: [mirelabsp](https://www.google.com/search?q=https://github.com/mirelabsp)
