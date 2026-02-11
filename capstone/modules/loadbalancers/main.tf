locals {
  fe-alb = merge(var.required_tags, { Name = "${var.lastname}-frontend-alb" })
  fe-tg = merge(var.required_tags, { Name = "${var.lastname}-frontend-tg" })
  fe-listener = merge(var.required_tags, { Name = "${var.lastname}-frontend-listener" })
  be-nlb = merge(var.required_tags, { Name = "${var.lastname}-backend-nlb" })
  be-tg = merge(var.required_tags, { Name = "${var.lastname}-backend-tg" })
  be-listener = merge(var.required_tags, { Name = "${var.lastname}-backend-listener" })

}
# 1. FRONTEND: APPLICATION LOAD BALANCER (HTTP)
resource "aws_lb" "frontend_alb" {
  name               = "${var.lastname}-frontend-alb"
  internal           = false  # Public facing
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_cidrs

  tags = local.fe-alb
}

resource "aws_lb_target_group" "frontend_tg" {
  name     = "${var.lastname}-frontend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = local.fe-tg
}

resource "aws_lb_listener" "frontend_http" {
  load_balancer_arn = aws_lb.frontend_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }

  tags = local.fe-listener
}

# 2. BACKEND: NETWORK LOAD BALANCER (TCP)
resource "aws_lb" "backend_nlb" {
  name               = "${var.lastname}-backend-nlb"
  internal           = true   # Internal only (Private Subnets)
  load_balancer_type = "network"
  subnets            = var.private_cidrs

  enable_cross_zone_load_balancing = true

  tags = local.be-nlb
}

resource "aws_lb_target_group" "backend_tg" {
  name     = "${var.lastname}-backend-tg"
  port     = 80
  protocol = "TCP"  # NLB uses TCP
  vpc_id   = var.vpc_id

  # TCP Health Check is standard for NLBs
  health_check {
    protocol            = "TCP"
    interval            = 30
    timeout             = 10 # Cannot be greater than interval for TCP
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = local.be-tg
}

resource "aws_lb_listener" "backend_tcp" {
  load_balancer_arn = aws_lb.backend_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }

  tags = local.be-listener
}