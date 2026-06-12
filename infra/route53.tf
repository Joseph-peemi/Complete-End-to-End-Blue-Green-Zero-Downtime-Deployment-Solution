resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = { Name = "${var.project_name}-zone" }
}

# Output the nameservers to update your domain registrar
output "route53_nameservers" {
  value       = aws_route53_zone.main.name_servers
  description = "Nameservers to update at your domain registrar"
}

output "route53_zone_id" {
  value       = aws_route53_zone.main.zone_id
  description = "Route53 hosted zone ID"
}