# ====== Networking Outputs ======
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "firewall_subnet_ids" {
  description = "IDs of the firewall subnets"
  value       = aws_subnet.firewall[*].id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# ====== ECR Outputs ======
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.app.name
}

# ====== ECS Outputs ======
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.app.name
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.app.arn
}

# ====== ALB Outputs ======
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_url" {
  description = "URL to access the application via ALB (HTTPS)"
  value       = "https://${aws_lb.main.dns_name}"
}

output "alb_http_url" {
  description = "HTTP URL (redirects to HTTPS)"
  value       = "http://${aws_lb.main.dns_name}"
}

output "target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.app.arn
}

# ====== Certificate Outputs ======
output "acm_certificate_arn" {
  description = "ARN of the ACM certificate for ALB HTTPS"
  value       = aws_acm_certificate.alb.arn
}

output "certificate_domain" {
  description = "Domain name on the self-signed certificate"
  value       = "${var.project_name}-alb.local"
}

# ====== Network Firewall Outputs ======
output "network_firewall_id" {
  description = "ID of the Network Firewall"
  value       = aws_networkfirewall_firewall.main.id
}

output "network_firewall_arn" {
  description = "ARN of the Network Firewall"
  value       = aws_networkfirewall_firewall.main.arn
}

output "network_firewall_policy_arn" {
  description = "ARN of the Network Firewall policy"
  value       = aws_networkfirewall_firewall_policy.main.arn
}
