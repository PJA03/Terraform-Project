/**
 * Module: Bastion Host (Jump Server)
 * Description: Deploys a secure entry point (Bastion Host) in the Public Subnet to allow 
 * administrative access to private instances.
 *
 * Resources Created:
 * - 1x AWS EC2 Instance: The Bastion server itself, launched in a Public Subnet.
 * - 1x Data Source (AWS AMI): Dynamically fetches the latest Amazon Linux 2023 AMI to ensure 
 *   the instance is always patched and up-to-date.
 *
 * Key Configurations:
 * - Network Placement: Placed strictly in `public_subnets[0]` to ensure internet reachability.
 * - Security: Attached to a specific Security Group (`bastion_sg_id`) that restricts inbound access (usually to admin IPs only).
 * - AMI Selection: Automatically filters for the latest `al2023-ami` (x86_64/HVM) owned by Amazon.
 */

locals {
  bastion_ec2_tags = merge(var.required_tags, { Name = "${var.lastname}-bastion-ec2" })
}

data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "bastion_ec2" {
  ami           = data.aws_ami.latest_amazon_linux.id
  instance_type = var.bastion_instance
  key_name      = var.key_name
  subnet_id     = var.public_subnets[0]

  # Associate the security group with the instance
  vpc_security_group_ids      = [var.bastion_sg_id]
  associate_public_ip_address = var.assoc_ip

  tags = local.bastion_ec2_tags
}