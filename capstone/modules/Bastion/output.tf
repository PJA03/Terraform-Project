output "bastion_public_ip" {
  description = "The public IP of the bastion host to connect via SSH"
  value       = aws_instance.bastion_ec2.public_ip
}

output "bastion_id" {
  description = "The ID of the Bastion Instance"
  value       = aws_instance.bastion_ec2.id
}

output "bastion_instance_id" {
  description = "The ID of the instance (useful for monitoring or scripts)"
  value       = aws_instance.bastion_ec2.id
}

output "ssh_command" {
  description = "Copy and paste this command to SSH into the bastion"
  # Assumes your SSH user is 'ec2-user' (default for Amazon Linux 2/2023)
  value       = "ssh -i galias-finalproject-keypair.pem ec2-user@${aws_instance.bastion_ec2.public_ip}"
}
