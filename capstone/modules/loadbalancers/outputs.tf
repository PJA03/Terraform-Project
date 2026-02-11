output "frontend_tg_arn" {
  value = aws_lb_target_group.frontend_tg.arn
}

output "backend_tg_arn" {
  value = aws_lb_target_group.backend_tg.arn
}

output "frontend_dns_name" {
  description = "The URL to access the frontend website"
  value       = aws_lb.frontend_alb.dns_name
}

output "backend_dns_name" {
  description = "The DNS name of the backend load balancer"
  value       = aws_lb.backend_nlb.dns_name
}