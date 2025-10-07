🚛 TMS — Transport Management System

TMS (Transport Management System) é uma API simples de gestão de transportes, desenvolvida com FastAPI, SQLModel e PostgreSQL, com containers orquestrados via Docker Compose.
O projeto faz parte de um estudo prático de DevOps + Desenvolvimento Backend com Python, com posterior integração à AWS.

🧩 Funcionalidades
Recurso	Descrição
🚗 Veículos	Cadastro, listagem, atualização e exclusão de veículos
👷 Motoristas	(em desenvolvimento)
🗺️ Rotas	(em desenvolvimento)
📦 Entregas	(em desenvolvimento)
⚙️ Tecnologias Utilizadas

Python 3.11

FastAPI

SQLModel

PostgreSQL

Docker & Docker Compose

Uvicorn

Git & GitHub

🧱 Estrutura do Projeto
tms/
├─ backend/
│  ├─ main.py               # Código principal da API
│  ├─ requirements.txt      # Dependências Python
│  ├─ Dockerfile            # Build da imagem da API
│  └─ ...
├─ docker-compose.yml       # Orquestra containers (API + DB)
└─ README.md                # Documentação do projeto

🚀 Como Rodar Localmente
🔧 Pré-requisitos

Docker e Docker Compose instalados
(verifique com docker --version e docker compose version)

▶️ Passos para executar
# Clone o repositório
git clone https://github.com/mirelabsp/tms.git
cd tms

# Suba os containers
docker compose up --build


A API ficará disponível em:
👉 http://localhost:8080

E o banco de dados PostgreSQL em:
👉 localhost:5432

🧠 Endpoints da API
Método	Endpoint	Descrição
POST	/veiculos/	Criar um novo veículo
GET	/veiculos/	Listar todos os veículos
PUT	/veiculos/{id}	Atualizar um veículo existente
DELETE	/veiculos/{id}	Remover um veículo do sistema
🧪 Exemplo de criação via curl:
curl -X POST "http://localhost:8080/veiculos/" \
-H "Content-Type: application/json" \
-d '{"placa":"ABC1234","modelo":"VW Cargo","capacidade":2.5}'

🔍 Testar via Swagger UI:

👉 http://localhost:8080/docs

🌩️ Próxima Fase — Integração com AWS

A Fase 2 do projeto levará o TMS para a nuvem, utilizando serviços AWS:

Serviço AWS	Uso planejado
ECS (Elastic Container Service)	Deploy dos containers da API
ECR (Elastic Container Registry)	Armazenar as imagens Docker
RDS (PostgreSQL)	Banco de dados gerenciado
CloudWatch	Logs e monitoramento
S3	Armazenamento de relatórios e exportações futuras
IAM	Controle de permissões e credenciais
CodePipeline + CodeBuild	Automação de CI/CD

🚀 O objetivo final é ter o TMS rodando 100% em nuvem, com versionamento contínuo e observabilidade.

📅 Roadmap do Projeto

 CRUD de veículos (Create e Read)

 Endpoint de atualização (Update)

 Endpoint de exclusão (Delete)

 CRUD de motoristas

 CRUD de rotas e entregas

 Deploy automatizado na AWS ECS

 Integração com AWS RDS

 Monitoramento com CloudWatch

 CI/CD com GitHub Actions + AWS CodePipeline

👩‍💻 Autoria

Desenvolvido por Mirela Santana 💜
Foco em DevOps | Cloud | Backend Python
📦 GitHub: mirelabsp