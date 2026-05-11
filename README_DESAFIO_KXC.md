**Desafio Técnico KXC - Infraestrutura AWS com Terraform**



**- Visão Geral**



Este projeto tem como objetivo provisionar e disponibilizar publicamente uma API containerizada utilizando serviços gerenciados da AWS, seguindo boas práticas de arquitetura em nuvem, segurança, escalabilidade e infraestrutura como código.



**A solução utiliza:**



\- Amazon ECS Fargate

\- Amazon RDS PostgreSQL

\- Application Load Balancer (ALB)

\- Amazon ECR

\- Terraform

\- Docker

\- VPC dedicada

\- CloudWatch Logs



\---



**TOPOLOGIA DA ARQUITETURA**



&#x20;                        INTERNET

&#x20;                            │

&#x20;                            ▼

&#x20;                ┌─────────────────────┐

&#x20;                │ Application Load    │

&#x20;                │ Balancer (ALB)      │

&#x20;                │ Porta 80            │

&#x20;                └─────────┬───────────┘

&#x20;                          │

&#x20;           ┌──────────────┴──────────────┐

&#x20;           ▼                             ▼

&#x20;  Public Subnet A                 Public Subnet B

&#x20;  10.0.1.0/24                     10.0.2.0/24

&#x20;  us-east-1a                      us-east-1b



&#x20;                          │

&#x20;                          ▼

&#x20;                ┌─────────────────────┐

&#x20;                │ ECS Fargate         │

&#x20;                │ Containers API      │

&#x20;                │ Porta 3000          │

&#x20;                └─────────┬───────────┘

&#x20;                          │

&#x20;           ┌──────────────┴──────────────┐

&#x20;           ▼                             ▼

&#x20; Private Subnet A               Private Subnet B

&#x20; 10.0.10.0/24                   10.0.11.0/24

&#x20; us-east-1a                     us-east-1b



&#x20;                          │

&#x20;                          ▼

&#x20;                ┌─────────────────────┐

&#x20;                │ RDS PostgreSQL      │

&#x20;                │ Privado             │

&#x20;                │ Porta 5432          │

&#x20;                └─────────────────────┘



&#x20;                          │

&#x20;                          ▼

&#x20;                   NAT Gateway

&#x20;                          │

&#x20;                          ▼

&#x20;                    Internet Gateway



\---



**VISÃO GERAL DA ARQUITETURA** 



Usuário Internet

&#x20;      │

&#x20;      ▼

Application Load Balancer (ALB)

&#x20;      │

&#x20;      ▼

ECS Fargate (containers API)

&#x20;      │

&#x20;      ▼

RDS PostgreSQL Privado



\---





**FLUXO COMPLETO DA APLICAÇÃO**





1\. Código Node.js

&#x20;       ↓

2\. Dockerfile

&#x20;       ↓

3\. Docker Build

&#x20;       ↓

4\. Imagem Docker

&#x20;       ↓

5\. Login no Amazon ECR

&#x20;       ↓

6\. Push da imagem para o ECR

&#x20;       ↓

7\. Terraform provisiona infraestrutura AWS

&#x20;       ↓

8\. ECS Fargate baixa imagem do ECR

&#x20;       ↓

9\. Container inicia no ECS

&#x20;       ↓

10\. ALB recebe tráfego HTTP

&#x20;       ↓

11\. ALB encaminha requisições para ECS

&#x20;       ↓

12\. API processa requisição

&#x20;       ↓

13\. ECS conecta no RDS PostgreSQL

&#x20;       ↓

14\. Banco retorna dados

&#x20;       ↓

15\. API responde usuário

&#x20;       ↓

16\. Logs enviados para CloudWatch



\---





**SERVIÇOS AWS UTILIZDOS** 





\- Amazon VPC

Responsável pelo isolamento lógico da infraestrutura em nuvem.



\- Subnets Públicas

Hospedam:

\- ALB

\- NAT Gateway



\- Subnets Privadas

Hospedam:

\- ECS Fargate

\- RDS PostgreSQL



\- Internet Gateway

Permite comunicação da VPC com a internet.



\- NAT Gateway

Permite saída para internet das instâncias privadas sem exposição pública.



\- ECS Fargate

Serviço gerenciado de containers sem necessidade de gerenciar servidores EC2.



\- Amazon ECR

Repositório de imagens Docker.



\- Application Load Balancer

Distribui o tráfego entre containers ECS.



\- Amazon RDS PostgreSQL

Banco de dados gerenciado pela AWS.



\- CloudWatch Logs

Centralização de logs da aplicação.



\- IAM Roles

Permissões seguras para ECS acessar serviços AWS.



\---



**SEGURANÇA DA ARQUITETURA**





\- Banco de dados privado

\- Containers executando em subnets privadas

\- Controle de acesso via Security Groups

\- Separação entre camada pública e privada

\- Logs centralizados no CloudWatch

\- Alta disponibilidade entre múltiplas AZs



\---



**COMANDOS TERRAFORM** 





Inicializar:



terraform init



Validar:



terraform validate



Executar plano:



terraform plan



Aplicar infraestrutura:



terraform apply



*# DESTRUIR INFRAESTRUTURA*

*############################################################*

*# Remove TODOS os recursos provisionados*



terraform destroy







**COMANDOS TERMINAL** 





aws ecr create-repository --repository-name simple-api --region us-east-1



docker build -t simple-api .



docker tag simple-api:latest 060651978771.dkr.ecr.us-east-1.amazonaws.com/simple-api:latest



docker push 060651978771.dkr.ecr.us-east-1.amazonaws.com/simple-api:latest



docker run -p 3000:3000 simple-api



aws ecs list-clusters



aws ecs list-services --cluster simple\_api



aws ecs list-tasks --cluster simple\_api



aws logs describe-log-groups



aws logs tail /ecs/simple-api --follow



aws elbv2 describe-load-balancers



aws rds describe-db-instances

































