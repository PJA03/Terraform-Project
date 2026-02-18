/**
 * Module: Security Layer (Firewalls)
 * Description: Defines the network access control boundaries using AWS Security Groups.
 * Implements Principle of Least Privilege.
 *
 * Resources Created:
 * 1. Public Security Groups:
 * - Bastion SG: Restricts SSH (Port 22) access to a single trusted IP (Administrator).
 * - ALB SG: Allows HTTP (Port 80) access from the global internet (0.0.0.0/0).
 *
 * 2. Private Application SGs (Dynamic):
 * - Frontend SG: associated with Frontend ASG instances.
 * - Backend SG: associated with Backend ASG instances.
 *
 * 3. Connectivity Rules:
 * - Internet -> ALB: Allowed.
 * - ALB -> Frontend: Traffic allowed ONLY from the ALB Security Group.
 * - Frontend -> Backend: Traffic allowed ONLY from the Frontend Security Group.
 * - Bastion -> All: SSH allowed ONLY from the Bastion Security Group.
 * - VPC -> Backend: Allows internal health checks (required for Network Load Balancer).
 */

# Locals for tagging
locals {
  bastion_sg_tags = merge(var.required_tags, { Name = "${var.lastname}-bastion-sg" })
  alb_sg_tags     = merge(var.required_tags, { Name = "${var.lastname}-alb-sg" })
  fe_sg_tags      = merge(var.required_tags, { Name = "${var.lastname}-frontend-sg" })
  be_sg_tags      = merge(var.required_tags, { Name = "${var.lastname}-backend-sg" })

  app_tiers = {
    frontend = local.fe_sg_tags
    backend  = local.be_sg_tags
  }
}

# PUBLIC SECURITY GROUPS
# Bastion SG: open to my ip only
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Allow SSH access to Bastion Host"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.access_ip] #access to my ip only
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.bastion_sg_tags
}

# PUBLIC ALB SECURITY GROUP
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP traffic from the internet to the ALB"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.alb_sg_tags
}

# Any to ALB
resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

# 2. APPLICATION SECURITY GROUPS (Frontend & Backend)
resource "aws_security_group" "app_sgs" {
  for_each = local.app_tiers

  name   = "${var.lastname}-${each.key}-sg"
  vpc_id = var.vpc_id
  tags   = each.value

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# CONNECTIVITY RULES (The Plumbing)
# Bastion SSH
resource "aws_security_group_rule" "bastion_ssh" {
  for_each = local.app_tiers

  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion_sg.id
  security_group_id        = aws_security_group.app_sgs[each.key].id
}

# Bastion HTTP
resource "aws_security_group_rule" "bastion_http" {
  for_each = local.app_tiers

  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion_sg.id
  security_group_id        = aws_security_group.app_sgs[each.key].id
}

# ALB -> FE
resource "aws_security_group_rule" "alb_to_frontend" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
  security_group_id        = aws_security_group.app_sgs["frontend"].id
}

# FE -> BE
resource "aws_security_group_rule" "frontend_to_backend" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app_sgs["frontend"].id
  security_group_id        = aws_security_group.app_sgs["backend"].id
}

# Backend Health Check
resource "aws_security_group_rule" "backend_allow_health_checks" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.app_sgs["backend"].id
}