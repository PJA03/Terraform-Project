locals {
  bastion_ec2_tags = merge(var.required_tags, { Name = "${var.lastname}-bastion-ec2" })
}

data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners = ["amazon"]

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
  key_name       = var.key_name
  subnet_id = var.public_subnets[0]

    # Associate the security group with the instance
  vpc_security_group_ids = [var.bastion_sg_id]
  associate_public_ip_address = var.assoc_ip

  tags = local.bastion_ec2_tags
}