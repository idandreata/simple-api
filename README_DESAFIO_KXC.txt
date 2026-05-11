Desafio Técnico KXC - Infraestrutura AWS com Terraform

- Visão Geral

Este projeto tem como objetivo provisionar e disponibilizar publicamente uma API containerizada utilizando serviços gerenciados da AWS, seguindo boas práticas de arquitetura em nuvem, segurança, escalabilidade e infraestrutura como código.

Acesso à aplicação

A aplicação está exposta através do Application Load Balancer:

- URL pública: http://tf-lb-20260511055853433900000009-181788438.us-east-1.elb.amazonaws.com


A solução utiliza:

- Amazon ECS Fargate
- Amazon RDS PostgreSQL
- Application Load Balancer (ALB)
- Amazon ECR
- Terraform
- Docker
- VPC dedicada
- CloudWatch Logs

---

TOPOLOGIA DA ARQUITETURA

                         INTERNET
                             │
                             ▼
                 ┌─────────────────────┐
                 │ Application Load    │
                 │ Balancer (ALB)      │
                 │ Porta 80            │
                 └─────────┬───────────┘
                           │
            ┌──────────────┴──────────────┐
            ▼                             ▼
   Public Subnet A                 Public Subnet B
   10.0.1.0/24                     10.0.2.0/24
   us-east-1a                      us-east-1b

                           │
                           ▼
                 ┌─────────────────────┐
                 │ ECS Fargate         │
                 │ Containers API      │
                 │ Porta 3000          │
                 └─────────┬───────────┘
                           │
            ┌──────────────┴──────────────┐
            ▼                             ▼
  Private Subnet A               Private Subnet B
  10.0.10.0/24                   10.0.11.0/24
  us-east-1a                     us-east-1b

                           │
                           ▼
                 ┌─────────────────────┐
                 │ RDS PostgreSQL      │
                 │ Privado             │
                 │ Porta 5432          │
                 └─────────────────────┘

                           │
                           ▼
                    NAT Gateway
                           │
                           ▼
                     Internet Gateway

---

VISÃO GERAL DA ARQUITETURA 

Usuário Internet
       │
       ▼
Application Load Balancer (ALB)
       │
       ▼
ECS Fargate (containers API)
       │
       ▼
RDS PostgreSQL Privado

---

FLUXO COMPLETO DA APLICAÇÃO

1. Código Node.js
        ↓
2. Dockerfile
        ↓
3. Docker Build
        ↓
4. Imagem Docker
        ↓
5. Login no Amazon ECR
        ↓
6. Push da imagem para o ECR
        ↓
7. Terraform provisiona infraestrutura AWS
        ↓
8. ECS Fargate baixa imagem do ECR
        ↓
9. Container inicia no ECS
        ↓
10. ALB recebe tráfego HTTP
        ↓
11. ALB encaminha requisições para ECS
        ↓
12. API processa requisição
        ↓
13. ECS conecta no RDS PostgreSQL
        ↓
14. Banco retorna dados
        ↓
15. API responde usuário
        ↓
16. Logs enviados para CloudWatch

---

SERVIÇOS AWS UTILIZDOS 

- Amazon VPC
Responsável pelo isolamento lógico da infraestrutura em nuvem.

- Subnets Públicas
Hospedam:
- ALB
- NAT Gateway

- Subnets Privadas
Hospedam:
- ECS Fargate
- RDS PostgreSQL

- Internet Gateway
Permite comunicação da VPC com a internet.

- NAT Gateway
Permite saída para internet das instâncias privadas sem exposição pública.

- ECS Fargate
Serviço gerenciado de containers sem necessidade de gerenciar servidores EC2.

- Amazon ECR
Repositório de imagens Docker.

- Application Load Balancer
Distribui o tráfego entre containers ECS.

- Amazon RDS PostgreSQL
Banco de dados gerenciado pela AWS.

- CloudWatch Logs
Centralização de logs da aplicação.

- IAM Roles
Permissões seguras para ECS acessar serviços AWS.

---

SEGURANÇA DA ARQUITETURA

- Banco de dados privado
- Containers executando em subnets privadas
- Controle de acesso via Security Groups
- Separação entre camada pública e privada
- Logs centralizados no CloudWatch
- Alta disponibilidade entre múltiplas AZs

---

COMANDOS TERRAFOM 


Inicializar:

terraform init

Validar:

terraform validate

Executar plano:

terraform plan

Aplicar infraestrutura:

terraform apply

# DESTRUIR INFRAESTRUTURA
############################################################
# Remove TODOS os recursos provisionados

terraform destroy



COMANDOS TERMINAL 

aws ecr create-repository --repository-name simple-api --region us-east-1

docker build -t simple-api .

docker tag simple-api:latest 060651978771.dkr.ecr.us-east-1.amazonaws.com/simple-api:latest

docker push 060651978771.dkr.ecr.us-east-1.amazonaws.com/simple-api:latest

docker run -p 3000:3000 simple-api

aws ecs list-clusters

aws ecs list-services --cluster simple_api

aws ecs list-tasks --cluster simple_api

aws logs describe-log-groups

aws logs tail /ecs/simple-api --follow

aws elbv2 describe-load-balancers

aws rds describe-db-instances















