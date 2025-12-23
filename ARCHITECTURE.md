# Architecture Documentation

## Overview

This document outlines the proposed AWS architecture for migrating Mashroom's JavaScript application from a single VM to a scalable, cloud-native deployment on AWS using ECS Fargate.

---

## Proposed AWS Architecture

### High-Level Design
```
Internet → Application Load Balancer → ECS Fargate Tasks → Node.js Application
           (Public Subnets)              (Private Subnets)
```

### Core Components

**Networking:**
- **VPC**: 10.0.0.0/16 CIDR block, isolated network
- **Subnets**: 
  - 2 Public subnets (10.0.1.0/24, 10.0.2.0/24) for ALB
  - 2 Private subnets (10.0.10.0/24, 10.0.11.0/24) for ECS tasks
- **Internet Gateway**: Allows public subnet internet access
- **NAT Gateway**: Allows private subnets outbound internet (for pulling images, etc.)
- **Multi-AZ**: Resources spread across 2 availability zones

**Compute:**
- **ECS Fargate**: Serverless container platform
  - No server management required
  - Task size: 0.25 vCPU, 512 MB memory
  - Runs Dockerized Node.js application
- **ECR**: Stores Docker images

**Load Balancing:**
- **Application Load Balancer**: 
  - Distributes traffic across ECS tasks
  - Health checks on `/health` endpoint every 30 seconds
  - Automatically removes unhealthy tasks from rotation

**Security:**
- **Security Groups**:
  - ALB SG: Allows HTTP (80) from internet
  - ECS SG: Only allows traffic from ALB on port 3000
- **IAM Roles**:
  - Task Execution Role: Pull images from ECR, write logs
  - Task Role: Application-level AWS permissions

**Monitoring:**
- **CloudWatch Logs**: Application logs from containers
- **CloudWatch Metrics**: CPU, memory, request counts

---

## How Scalability is Handled

### Auto-Scaling
- **ECS Service Auto-Scaling**: Scales based on CPU utilization
  - Target: 70% CPU usage
  - Min tasks: 2 (for high availability)
  - Max tasks: 10 (cost control)
  - Scale out: Add task when CPU > 70% for 2 minutes
  - Scale in: Remove task when CPU < 50% for 5 minutes

### Load Distribution
- ALB automatically distributes requests across all healthy tasks
- Round-robin algorithm ensures even distribution
- Cross-zone load balancing for optimal resource usage

### Why This Works
For a JavaScript application with variable traffic, ECS auto-scaling provides:
- Automatic capacity adjustment without manual intervention
- Cost savings during low-traffic periods
- Ability to handle traffic spikes

---

## How Reliability is Addressed

### High Availability
- **Multi-AZ Deployment**: Application runs in 2 availability zones
  - If one AZ fails, the other continues serving traffic
  - ALB automatically routes traffic to healthy AZ
- **Minimum Task Count**: Always maintain at least 2 running tasks
- **Health Checks**: ALB pings `/health` every 30 seconds
  - 2 consecutive failures = task marked unhealthy
  - Unhealthy tasks removed from load balancer rotation

### Fault Tolerance
- **Auto-Restart**: ECS automatically replaces crashed tasks within 2-3 minutes
- **Rolling Deployments**: Updates happen gradually
  - Deploy to 50% of tasks at a time
  - New tasks must pass health checks before old ones are terminated
- **Circuit Breaker**: Deployment stops if new tasks fail health checks

---

## How Security is Addressed

### Network Security (Defense in Depth)
1. **Public Layer**: ALB in public subnets accepts internet traffic
2. **Private Layer**: ECS tasks in private subnets, no direct internet access
3. **Security Groups**:
   - ALB: Allows port 80/443 from anywhere
   - ECS: Only allows port 3000 from ALB security group

### Access Control
- **IAM Roles**: Each component has minimal required permissions
  - Task Execution Role: ECR pull, CloudWatch write
  - Task Role: Application-specific permissions (S3, DynamoDB, etc.)
- **No Hardcoded Secrets**: Secrets injected via AWS Secrets Manager at runtime

### Additional Measures
- Container image scanning in ECR (vulnerability detection)
- VPC Flow Logs for network traffic audit
- Private subnets prevent direct access to application

---

## CI/CD Strategy

### Pipeline Flow
```
Code Push → Build → Test → Docker Build → Push to ECR → Deploy to ECS
```

### Pipeline Stages

**1. Build & Test** (~2 min)
- Install dependencies
- Run unit tests
- Lint code

**2. Docker Build** (~3 min)
- Build optimized Docker image
- Tag with git SHA and 'latest'

**3. Push to Registry** (~2 min)
- Authenticate with ECR
- Push image with multiple tags

**4. Deploy** (~5 min)
- Update ECS task definition with new image
- Trigger rolling deployment
- Wait for health checks to pass

**Total deployment time: ~12 minutes**

### Rollback Strategy
- Keep last 10 task definition revisions
- One command rollback: Update service to previous task definition
- Automatic rollback if new tasks fail health checks

---

## Key Trade-offs and Assumptions

### Trade-offs

**ECS Fargate vs EKS (Kubernetes)**
- **Chose**: ECS Fargate
- **Why**: Simpler to operate, no cluster management, sufficient for single application
- **Trade-off**: Less flexibility, harder to migrate to multi-cloud later

**ECS Fargate vs EC2**
- **Chose**: Fargate
- **Why**: No server patching, auto-scaling easier, pay only for container runtime
- **Trade-off**: Slightly higher cost per hour, less control over underlying infrastructure

**Single Region**
- **Chose**: Deploy in one AWS region
- **Why**: Simpler architecture, lower cost, meets current needs
- **Trade-off**: No geographic redundancy, higher latency for distant users

### Assumptions

- Traffic is **< 1000 requests/second** (justifies current scaling limits)
- Application is **stateless** (no sticky sessions needed)
- **Budget**: ~$150-200/month for baseline infrastructure
- **Availability target**: 99.9% uptime (3 nines, not 4)
- This is a **single application**, not microservices

### Known Limitations

1. **No CDN**: Static assets served directly from ALB (no edge caching)
2. **No Database**: Database layer not included in this phase
3. **Basic Monitoring**: No advanced APM tool (DataDog, New Relic)
4. **LocalStack Limitations**: Some AWS features behave differently locally
5. **HTTP Only**: No HTTPS/SSL configured (would use ACM in production)

---

## Future Enhancements

### Phase 1 (Next 1-2 months)
- Add RDS PostgreSQL database with Multi-AZ
- Implement HTTPS with ACM certificate
- Add staging environment
- Enhanced monitoring and alerting

### Phase 2 (3-6 months)
- CloudFront CDN for static assets
- Blue-green deployment strategy
- Multi-region disaster recovery
- WAF for DDoS protection

### Phase 3 (6+ months, if needed)
- Migrate to EKS if application becomes microservices
- Advanced observability (distributed tracing)
- Chaos engineering practices

---

## Conclusion

This architecture provides a solid foundation for Mashroom's application with reasonable complexity and cost. It follows AWS best practices for high availability, security, and scalability while remaining practical for a small team to operate. The design allows for incremental improvements as the application and requirements evolve.