# Mashroom AWS Infrastructure (Terraform)

## Overview

This repository contains the **Terraform infrastructure-as-code** used to deploy Mashroom’s **Dockerized Node.js application** on an **AWS-like environment emulated by LocalStack Pro**.

The setup mirrors a real AWS production architecture using:
- **ECS Fargate**
- **Application Load Balancer (ALB)**
- **ECR**
- **VPC with public and private subnets**

This allows  **local development and experimentation** without deploying to a real AWS account.

For architectural decisions and trade-offs, see [`ARCHITECTURE.md`](../ARCHITECTURE.md).

---

## Architecture Summary

**High-level flow (emulated):**

Client
↓
Application Load Balancer (LocalStack)
↓
ECS Fargate Tasks (LocalStack)
↓
Node.js Application (Docker)

---

## Emulation Environment

This project is designed to run on:

- **LocalStack Pro**
- Docker-based AWS service emulation
- No real AWS resources are created
---

## Load Balancer Configuration

- Internet-facing ALB (emulated)
- Deployed across **two public subnets**
- Routes traffic to ECS tasks via a target group
- Health checks on `/health`

---

## ECS & Application

- **Launch Type**: Fargate (emulated)
- **Application**: Node.js (Dockerized)
- **Image Source**: Amazon ECR (LocalStack)

### Networking
- Tasks run in **private subnets**

### Port Mapping
- ALB → ECS tasks on port **3000**

---

## Repository Structure

```bash
.
├── ecs-cluster.tf        # ECS cluster definition
├── ecs-task.tf           # ECS task & service definitions
├── alb.tf                # Application Load Balancer & listeners
├── security.tf           # Security groups & IAM roles
├── variables.tf          # Input variables
├── subnets.tf            # Public & private subnet definitions
├── versions.tf           # Terraform & provider versions
├── vpc.tf                # VPC configuration
├── provider.tf           # AWS / LocalStack provider configuration
├── outputs.tf            # Useful outputs (ALB endpoint)
└── README.md             # This file
```
## Prerequisites

Before deploying, ensure you have:

- **Terraform ≥ 1.3**
- **Docker**
- **LocalStack Pro**
- **AWS CLI** (configured for LocalStack)

### Example AWS CLI Configuration for LocalStack

```bash
aws configure set aws_access_key_id test
aws configure set aws_secret_access_key test
aws configure set region us-east-1
```
1. Start LocalStack
```bash
localstack start -d
```

2. Build the Docker Image

Make sure you are inside your app directory (where the Dockerfile is).
```bash
docker build -t mashroom-app .
```

3. Create the ECR Repository in LocalStack

Using AWS CLI with explicit endpoint + region (example: us-east-1):
```bash
aws --endpoint-url=http://localhost:4566 \
    ecr create-repository \
    --repository-name mashroom-app \
    --region us-east-1 \
    --image-scanning-configuration scanOnPush=true
```
4. Tag the Image for LocalStack ECR

LocalStack ECR format:

000000000000.dkr.ecr.<region>.localhost.localstack.cloud:4566/<repo>


Example:
```bash
docker tag mashroom-app \
  000000000000.dkr.ecr.us-east-1.localhost.localstack.cloud:4566/mashroom-app
```

5. Push the Image to LocalStack ECR
```bash
docker push \
  000000000000.dkr.ecr.us-east-1.localhost.localstack.cloud:4566/mashroom-app
```


6. Initialize Terraform
```bash
terraform init
```

7. Deploy the Infrastructure
```bash
terraform apply
```

8. Access the Application
Terraform will output the ALB DNS name.

Example (LocalStack):

http://mashroom-lb.localhost.localstack.cloud


Actual hostname may vary based on your LocalStack config.

## Scaling & Availability (Emulated)

- **Multi-AZ behavior** is logically simulated
- **Minimum of 2 ECS tasks**
- **CPU-based auto-scaling** (emulated)
- **ALB health checks** automatically remove unhealthy tasks

---

## Security Model

- **ALB** is the only public entry point
- **ECS tasks** are isolated in private subnets
- **Security groups** enforce strict traffic flow:
  - ALB: Allows HTTP (80)
  - ECS: Allows port 3000 only from ALB security group
- **IAM roles and policies** are evaluated by LocalStack
