output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "ecs_tasks_security_group_id" {
  value = aws_security_group.ecs_tasks.id
}

output "app_secrets_arn" {
  value = aws_secretsmanager_secret.app.arn
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "ecr_repository_url" {
  description = "Full ECR repository URL used in pipeline docker push commands"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_name" {
  description = "Short repository name used in lifecycle and policy resources"
  value       = aws_ecr_repository.app.name
}

output "ecr_registry_id" {
  description = "AWS account ID that owns the registry — used in docker login"
  value       = aws_ecr_repository.app.registry_id
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions_deploy.arn
  description = "Paste this into your GitHub Actions workflow as role-to-assume"
}

output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task.arn
}

output "alarm_names" {
  value = [
    aws_cloudwatch_metric_alarm.http_5xx.alarm_name,
    aws_cloudwatch_metric_alarm.latency_p99.alarm_name,
    aws_cloudwatch_metric_alarm.unhealthy_hosts.alarm_name
  ]
  description = "Paste these into rollback.sh ALARM_NAMES array"
}

output "certificate_status" {
  value       = aws_acm_certificate.main.status
  description = "Certificate status — should change from PENDING_VALIDATION to ISSUED"
}

output "certificate_arn" {
  value = aws_acm_certificate.main.arn
}

output "alb_listener_arn" {
  value       = aws_lb_listener.http.arn
  description = "Main HTTP listener ARN — used by switch-traffic.sh"
}

output "target_group_green_arn" {
  value = aws_lb_target_group.green.arn
}

output "target_group_blue_arn" {
  value = aws_lb_target_group.blue.arn
}
