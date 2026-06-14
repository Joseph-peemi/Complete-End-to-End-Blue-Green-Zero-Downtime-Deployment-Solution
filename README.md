Here’s a clean, structured README you can copy and paste. It’s written to reflect your actual setup, including the problems you hit and what the system really does (not fantasy assumptions).

---

# Blue-Green Zero Downtime Deployment on AWS (ECS + ALB + GitHub Actions)

## Overview

This project implements a **blue-green deployment pipeline** for an ASP.NET Core API running on **AWS ECS Fargate behind an Application Load Balancer (ALB)**. The system is automated using **GitHub Actions** and provisions infrastructure using **Terraform**.

The goal is to achieve:

* Zero-downtime deployments
* Automated health validation
* Rollback capability
* Containerized CI/CD pipeline with ECR
* Implement monitoring (Metric → Alarm → SNS → Email → You)

---

## Architecture

### Core Components

* **ASP.NET Core API**
* **Docker**
* **Amazon ECS (Fargate)**

  * Blue service: `svc-blue`
  * Green service: `svc-green`
* **Application Load Balancer (ALB)**
* **ECR (Docker Registry)**
* **CloudWatch (Monitoring & Alarms)**
* **SNS (Email notifications)**
* **GitHub Actions (CI/CD Pipeline)**

---

## Deployment Strategy (Blue-Green)

1. New version is built and pushed to **ECR**
2. Image is deployed to the **idle environment (blue or green)**
3. Health checks run against the new environment
4. If healthy → traffic switches via ALB
5. If unhealthy → rollback is triggered

---

## CI/CD Pipeline (GitHub Actions)

Pipeline stages:

### 1. Build & Test

* Restores .NET dependencies
* Runs unit tests
* Builds application

### 2. Docker Build & Push

* Builds Docker image
* Pushes to Amazon ECR
* Tags images using commit SHA + `candidate`

### 3. Deploy to ECS (Idle Slot)

* Detects active slot (blue/green)
* Updates ECS task definition
* Deploys new version to idle service

### 4. Health Check Validation

* Calls `/health` endpoint
* Confirms service stability

### 5. Traffic Switch

* ALB target group weight shift
* Blue → Green or Green → Blue

### 6. Post-Deployment Monitoring

* CloudWatch alarms monitor failures
* SNS sends notifications (email-based alerts)

---

## Key Issues Encountered & Fixes

### 1. Docker build failures (dotnet restore / publish issues)

**Cause:**

* Incorrect working directory assumptions
* Missing project file paths in Docker build context

**Fix:**

* Explicitly referenced `.csproj` paths
* Ensured correct COPY order in Dockerfile

---

### 2. Missing Swagger in production

**Cause:**

* Swagger enabled only in Development mode

**Fix:**

* In production ECS environment, `ASPNETCORE_ENVIRONMENT=Production`
* Swagger is intentionally disabled unless explicitly enabled

---

### 3. ECS container name mismatch error

**Cause:**

* Task definition container name did not match ECS service configuration

**Fix:**

* Ensured consistency across:

  * ECS task definition `containerDefinitions.name`
  * ECS service `load_balancer.container_name`

---

### 4. Secrets Manager failures

**Cause:**

* ECS task referencing a secret version that did not exist

**Fix:**

* Corrected secret ARN and ensured `AWSCURRENT` version exists

---

### 5. SNS alarm notifications not working

**Cause:**

* SNS subscription remained in `PendingConfirmation`

**Fix:**

* Email subscription must be confirmed manually before alerts work

---

### 6. ImageNotFound errors in ECR

**Cause:**

* Incorrect image tag referenced in deployment step

**Fix:**

* Standardized tagging strategy:

  * `sha-<commit>`
  * `candidate`

---

## API Endpoints

### Health Check

```
GET /health
```

Returns:

```json
{
  "status": "Healthy",
  "slot": "blue|green",
  "version": "image-tag",
  "checks": [...]
}
```

---

### Product API (if implemented)

```
GET /api/products
```

---

### Order API (if implemented)

```
GET /api/orders
```

---

## Infrastructure (Terraform)

* ECS Cluster: `blue-green-deployment-cluster`
* Services:

  * `svc-blue`
  * `svc-green`
* Task Definitions:

  * `aspnetapp-blue`
  * `aspnetapp-green`
* Load Balancer:

  * ALB with two target groups (blue/green)

---

## Monitoring & Alerts

### CloudWatch

* Monitors:

  * Task failures
  * ALB health checks
  * Service stability

### SNS

* Sends email notifications on alarm trigger
* Requires manual confirmation of subscription

---

## Important Lessons Learned

* ECS does NOT generate API routes; controllers must exist in code
* ALB only routes traffic; it does not fix application errors
* Most deployment failures came from:

  * wrong task definitions
  * missing secrets
  * incorrect container naming
* “Infrastructure is healthy” does NOT mean “application is working”

---

## How to Access the Application

### Health endpoint (always available)

```
http://<ALB-DNS>/health
```

## Zero-Downtime Guarantee

Achieved by:

* Running blue and green services simultaneously
* Shifting ALB traffic only after health validation
* Retaining previous version for instant rollback

---

## Future Improvements

* Add Route53 weighted DNS switching
* Add automated rollback Lambda triggered by CloudWatch alarms
* Add full integration tests in pipeline
* Add distributed tracing (X-Ray or OpenTelemetry)

---
