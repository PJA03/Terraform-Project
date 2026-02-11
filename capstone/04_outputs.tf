output "bastion_public_ip" {
  description = "Public IP Address of the Bastion Host"
  value       = module.bastion_host.bastion_public_ip
}

output "bastion_ssh_command" {
  description = "Run this command to SSH into your Bastion"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${module.bastion_host.bastion_public_ip}"
}

output "frontend_endpoint" {
  description = "Click this URL to access your website"
  value       = "http://${module.loadbalancers.frontend_dns_name}"
}