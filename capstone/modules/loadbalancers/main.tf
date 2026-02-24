/**
 * Module: Load Balancing Layer
 * Description: Deploys the traffic distribution layer, separating public access from internal communication.
 *
 * Resources Created:
 * 1. Frontend Application Load Balancer (ALB):
 * - Type: Application (Layer 7 -  application layer / HTTP).
 * - Scheme: Internet-facing (Public Subnets).
 * - Function: Routes external user traffic to the Frontend Auto Scaling Group.
 * - Health Check: Monitors HTTP status 200 on path "/".
 *
 * 2. Backend Network Load Balancer (NLB):
 * - Type: Network (Layer 4 - transport layer / TCP).
 * - Scheme: Internal-only (Private Subnets).
 * - Function: Routes internal traffic from Frontend instances to the Backend Auto Scaling Group.
 * - Health Check: Monitors TCP connection health.
 *
 * Key Features:
 * - Security: Backend NLB is strictly internal; it has no public IP and cannot be reached from the internet.
 * - Performance: Uses TCP (Layer 4) for the backend for high-throughput, low-latency communication between tiers.
 * - Resilience: Cross-zone load balancing is enabled to distribute traffic across all Availability Zones.
 */

locals {
  fe-alb      = merge(var.required_tags, { Name = "${var.lastname}-frontend-alb" })
  fe-tg       = merge(var.required_tags, { Name = "${var.lastname}-frontend-tg" })
  fe-listener = merge(var.required_tags, { Name = "${var.lastname}-frontend-listener" })
  be-nlb      = merge(var.required_tags, { Name = "${var.lastname}-backend-nlb" })
  be-tg       = merge(var.required_tags, { Name = "${var.lastname}-backend-tg" })
  be-listener = merge(var.required_tags, { Name = "${var.lastname}-backend-listener" })

}
# 1. FRONTEND: APPLICATION LOAD BALANCER (HTTP)
resource "aws_lb" "frontend_alb" {
  name               = "${var.lastname}-frontend-alb"
  internal           = false # Public facing
  load_balancer_type = var.fe_lb_type
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
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = var.health_check_matcher
    interval            = var.tg_interval
    timeout             = var.tg_timeout
    healthy_threshold   = var.tg_healthy_threshold
    unhealthy_threshold = var.tg_unhealthy_threshold
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
  internal           = true # Internal only (Private Subnets)
  load_balancer_type = var.be_lb_type
  subnets            = var.private_cidrs

  # distribute traffic across all Availability Zones
  enable_cross_zone_load_balancing = true

  tags = local.be-nlb
}

resource "aws_lb_target_group" "backend_tg" {
  name     = "${var.lastname}-backend-tg"
  port     = 80
  protocol = "TCP" # NLB uses TCP
  vpc_id   = var.vpc_id

  # TCP Health Check is standard for NLBs
  health_check {
    protocol            = "TCP"
    interval            = var.tg_interval
    timeout             = var.tg_timeout
    healthy_threshold   = var.tg_healthy_threshold
    unhealthy_threshold = var.tg_unhealthy_threshold
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