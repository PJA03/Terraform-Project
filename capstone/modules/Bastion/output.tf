output "bastion_public_ip" {
  description = "The public IP of the bastion host to connect via SSH"
  value       = aws_instance.bastion_ec2.public_ip
}