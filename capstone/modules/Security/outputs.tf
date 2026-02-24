output "bastion_sg_id" {
  description = "ID of the Bastion Security Group"
  value       = aws_security_group.bastion_sg.id
}

output "alb_sg_id" {
  description = "ID of the Application Load Balancer Security Group"
  value       = aws_security_group.alb_sg.id
}

output "frontend_sg_id" {
  value = aws_security_group.app_sgs["frontend"].id
}

output "backend_sg_id" {
  value = aws_security_group.app_sgs["backend"].id
}