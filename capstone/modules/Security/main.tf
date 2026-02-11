# Locals for tagging
locals {
  bastion_sg_tags        = merge(var.required_tags, { Name = "${var.lastname}-bastion-sg" })
  alb_sg_tags        = merge(var.required_tags, { Name = "${var.lastname}-alb-sg" })
  fe_sg_tags        = merge(var.required_tags, { Name = "${var.lastname}-frontend-sg" })
  be_sg_tags        = merge(var.required_tags, { Name = "${var.lastname}-backend-sg" })

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
    from_port   = var.ssh_port
    to_port     = var.ssh_port
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

# ==========================================================
# 1. PUBLIC ALB SECURITY GROUP
# ==========================================================
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP traffic from the internet to the ALB"
  vpc_id      = var.vpc_id

  # NOTE: We removed the inline 'ingress' block here to keep it clean
  # We will add it as a rule below.

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.alb_sg_tags
}

# Rule: Allow the World to talk to the ALB
resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

# ==========================================================
# 2. APPLICATION SECURITY GROUPS (Frontend & Backend)
# ==========================================================
resource "aws_security_group" "app_sgs" {
  for_each = local.app_tiers

  name   = "${var.lastname}-${each.key}-sg"
  vpc_id = var.vpc_id
  tags   = each.value

  # === CRITICAL FIX: NO INLINE INGRESS BLOCKS HERE ===
  # We moved the Bastion rules to "aws_security_group_rule" below.
  # This prevents them from blocking the Load Balancer rules.

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ==========================================================
# 3. CONNECTIVITY RULES (The Plumbing)
# ==========================================================

# --- BASTION ACCESS (SSH) ---
resource "aws_security_group_rule" "bastion_ssh" {
  for_each = local.app_tiers

  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion_sg.id
  security_group_id        = aws_security_group.app_sgs[each.key].id
}

# --- BASTION ACCESS (HTTP Testing) ---
resource "aws_security_group_rule" "bastion_http" {
  for_each = local.app_tiers

  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion_sg.id
  security_group_id        = aws_security_group.app_sgs[each.key].id
}

# --- FRONTEND: Allow ALB to talk to Frontend ---
resource "aws_security_group_rule" "alb_to_frontend" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
  security_group_id        = aws_security_group.app_sgs["frontend"].id
}

# --- BACKEND: Allow Frontend to talk to Backend ---
resource "aws_security_group_rule" "frontend_to_backend" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app_sgs["frontend"].id
  security_group_id        = aws_security_group.app_sgs["backend"].id
}

# --- BACKEND: Allow VPC (NLB Health Checks) ---
resource "aws_security_group_rule" "backend_allow_health_checks" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/16"] # Ensure this matches your VPC CIDR
  security_group_id = aws_security_group.app_sgs["backend"].id
}