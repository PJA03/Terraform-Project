# 1. Find all instances that belong to the Frontend ASG
data "aws_instances" "frontend_instances" {
  instance_tags = {
    Name = "${var.lastname}-frontend-asg" # Must match the tag you gave them!
  }

  instance_state_names = ["running"]
  depends_on           = [aws_autoscaling_group.frontend_asg]
}

output "frontend_connect_ip" {
  description = "SSH Connection IP (First Instance)"
  # The try() function prevents errors if the ASG is empty (0 instances)
  value = try(data.aws_instances.frontend_instances.private_ips[0], "No instances running")
}