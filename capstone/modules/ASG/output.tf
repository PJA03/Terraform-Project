# looks for all instances that belong to the Frontend ASG
data "aws_instances" "frontend_instances" {
  instance_tags = {
    Name = "${var.lastname}-frontend-asg"
  }

  instance_state_names = ["running"]
  depends_on           = [aws_autoscaling_group.frontend_asg]
}

output "frontend_connect_ip" {
  description = "SSH Connection IP"
  # Error handling for when no instances are found
  # fallback value instead of having error when no instances
  value = try(data.aws_instances.frontend_instances.private_ips[0], "No instances running")
}