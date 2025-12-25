# Mashroom Project

## Overview

Mashroom is a **Dockerized Node.js application** deployed on an **AWS-like environment**, emulated locally using **LocalStack Pro**. The project demonstrates:

- **Cloud-native architecture** with ECS, ALB, and ECR  
- **Infrastructure as Code (IaC)** with Terraform  
- **CI/CD pipeline** for automated builds, tests, and deployments  

This repository contains both the **application code** and the **Terraform infrastructure** to deploy it.


## Application Overview

- **Tech Stack:** Node.js, Docker  

- **Architecture:**  
  Client → ALB → ECS Fargate Tasks → Node.js Application  

- **Networking:** ECS tasks run in **private subnets**, ALB is the only public entry point  

- **Port Mapping:** ALB → ECS tasks on **port 3000**  

For full infrastructure details, see the [Terraform README](./terraform/README.md).

## CI/CD Pipeline

The project uses **GitHub Actions** for:

- Building and testing the Docker image  
- Pushing the image to **LocalStack ECR**  
- Deploying infrastructure with **Terraform**  
- Updating ECS services automatically  

> **Note:** The CI/CD workflow is designed to work in a **LocalStack emulated AWS environment**, not real AWS.

---

## Getting Started (Local Setup)

### Prerequisites

- **Docker**  
- **LocalStack Pro**  
- **Terraform ≥ 1.3**  
- **AWS CLI** configured for LocalStack  

### Quick Start

1. **Start LocalStack**:
```bash
localstack start -d
```

### Build the Docker Image

Navigate to the app directory and build the Docker image:

```bash
cd app
docker build -t mashroom-app .
```

Deploy Infrastructure

Follow the Terraform README for ECR setup and infrastructure deployment:
[Terraform README](./terraform/README.md)

Access the Application

Once Terraform deploys the infrastructure, access the app via the ALB URL output by Terraform:

http://mashroom-lb.localhost.localstack.cloud:4566

