variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}
variable "project_name" {
  description = "Name of the project for tagging resources"
  type        = string
  default     = "blue-green-deployment"
}
variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
  default     = "production"
}
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}
variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}
variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}
variable "github_org" {
  description = "GitHub organization name for OIDC trust"
  type        = string
  default     = "my-github-org"
}
variable "github_repo" {
  description = "GitHub repository name for OIDC trust"
  type        = string
  default     = "my-repo"
}

variable "elb_account_id" {
  description = "AWS account ID that owns the ELB service (for S3 bucket policy)"
  type        = string
  default     = "127311923021" # ELB service account ID for us-east-1 (https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html#access-log-restrictions)
}
variable "log_retention_days" {
  description = "Number of days to retain logs in CloudWatch"
  type        = number
  default     = 14
}
variable "app_secret_name" {
  description = "Name of the secret in AWS Secrets Manager that contains application secrets"
  type        = string
  default     = "app-secrets"
}
variable "task_cpu" {
  description = "CPU units for the ECS task (e.g., 256, 512, 1024)"
  type        = number
  default     = 512
}
variable "task_memory" {
  description = "Memory in MiB for the ECS task (e.g., 512, 1024, 2048)"
  type        = number
  default     = 1024
}

variable "container_name" {
  description = "Name of the container in the task definition (used for logging and load balancer)"
  type        = string
  default     = "aspnetapp"
}
variable "container_port" {
  description = "Port on which the container listens (used for health checks and load balancer)"
  type        = number
  default     = 8080
}
variable "service_desired_count" {
  description = "Number of desired tasks for the ECS service"
  type        = number
  default     = 2
}
variable "alert_email" {
  description = "Email address to receive CloudWatch alarm notifications"
  type        = string
  default     = "peemijoe9522@gmail.com"
}

variable "domain_name" {
  type        = string
  description = "Domain name for ACM certificate (e.g., example.com)"
}

variable "route53_zone_id" {
  type        = string
  description = "Route53 hosted zone ID for DNS validation"
}
