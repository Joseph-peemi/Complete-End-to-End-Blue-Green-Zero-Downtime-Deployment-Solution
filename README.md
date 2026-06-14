# Complete End-to-End Blue-Green Zero-Downtime Deployment Solution

[![.NET](https://img.shields.io/badge/.NET-8.0-blue.svg)](https://dotnet.microsoft.com/)
[![AWS](https://img.shields.io/badge/AWS-ECS%20Fargate-orange.svg)](https://aws.amazon.com/ecs/)
[![Terraform](https://img.shields.io/badge/Terraform-Infrastructure-623CE4.svg)](https://www.terraform.io/)
[![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF.svg)](https://github.com/features/actions)

A production-grade **blue-green deployment** implementation for an ASP.NET Core API on **AWS ECS Fargate** with **zero downtime**, automated health checks, rollback capability, and comprehensive monitoring.

## 🎯 Overview

This project demonstrates a complete, real-world **blue-green deployment pipeline** using:

- **ASP.NET Core 8** API
- **Docker** containerization
- **AWS ECS Fargate** (Blue & Green services)
- **Application Load Balancer (ALB)** for traffic switching
- **Terraform** for infrastructure as code
- **GitHub Actions** for CI/CD
- **Amazon ECR** as container registry
- **CloudWatch + SNS** for monitoring and alerts

The solution ensures **zero downtime** during deployments by deploying the new version to the idle environment, validating it, and then switching traffic.

## 🏗️ Architecture

### Core Components
- **Application**: ASP.NET Core Web API (`MyApi`)
- **Infrastructure**: Terraform (VPC, ECS Cluster, ALB, Target Groups, etc.)
- **Blue/Green Services**: Two identical ECS services (`svc-blue` & `svc-green`)
- **Load Balancing**: ALB with two target groups
- **Registry**: Amazon ECR
- **Monitoring**: CloudWatch alarms + SNS email notifications
- **CI/CD**: GitHub Actions workflow

## 🚀 Deployment Strategy (Blue-Green)

1. Build & test the .NET application
2. Build and push Docker image to ECR (tagged with commit SHA)
3. Deploy new version to the **idle** environment (blue → green or green → blue)
4. Run automated health checks against the new environment
5. Switch ALB traffic to the healthy environment
6. Monitor post-deployment with CloudWatch

**Rollback** is automatic if health checks fail.

## 📁 Project Structure
├── MyApi/                  # ASP.NET Core Web API

├── MyApi.Tests/            # Unit tests

├── infra/                  # Terraform infrastructure

├── .github/workflows/      # GitHub Actions CI/CD

├── scripts/                # Helper scripts

├── Dockerfile

├── .trivyignore

└── README.md


## 🔄 CI/CD Pipeline (GitHub Actions)

The pipeline includes:

- Dependency restore & build
- Unit testing
- Docker image build with Trivy security scan
- Push to Amazon ECR
- Deploy to idle ECS service
- Health validation
- Traffic switch via ALB
- Post-deployment monitoring

## 🛠️ Key Challenges & Solutions

- Fixed Docker build context and multi-stage build issues
- Resolved ECS container name mismatches
- Handled Secrets Manager versioning correctly
- Ensured proper SNS subscription confirmation for alerts
- Standardized image tagging strategy (`sha-<commit>` + `candidate`)

## 📡 API Endpoints

### Health Check
```http
GET /health
```
Returns environment slot, version, and health status.
🧪 How to Use

Clone the repository
Update infra/terraform.tfvars and variables with your AWS details
Apply Terraform infrastructure (terraform apply)
Configure GitHub repository secrets for AWS credentials
Push code to trigger the GitHub Actions pipeline

📋 Prerequisites

AWS account with appropriate permissions
Terraform >= 1.0
GitHub repository with Actions enabled
Configured AWS credentials in GitHub Secrets

🎓 Lessons Learned

Infrastructure health ≠ Application health
Container names and task definitions must match exactly
Always validate health checks before switching traffic
Manual confirmation is required for SNS email subscriptions

🔮 Future Enhancements

Route 53 weighted routing
Automated rollback Lambda
OpenTelemetry distributed tracing
Advanced integration testing
### Returns environment slot, version, and health status.


### Additional Recommendations for the Repo:

1. **Repository Description** (add on GitHub):
   > Complete end-to-end blue-green zero-downtime deployment solution using ASP.NET Core, AWS ECS Fargate, Terraform, and GitHub Actions.

2. **Topics** (recommended):
   `blue-green-deployment` `zero-downtime` `aws-ecs` `fargate` `terraform` `github-actions` `devops` `cicd` `aspnet-core` `infrastructure-as-code` `aws-cloudwatch`

This version keeps the authentic details from your existing README while making it cleaner, more professional, and easier to read. Let me know if you want any specific sections expanded or adjusted!
