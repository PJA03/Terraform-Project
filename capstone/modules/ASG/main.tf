/**
 * Module: Compute Layer (Auto Scaling)
 * Description: Deploys the Frontend and Backend compute infrastructure using
 * Auto Scaling Groups (ASG) for high availability and dynamic scaling.
 *
 * Resources Created:
 * - 2x Launch Templates: Defines instance specs (AMI, Type, User Data, Security Groups) for Frontend/Backend.
 * - 2x Auto Scaling Groups: Manages lifecycle of instances (Min: 2, Max: 4) across private subnets.
 * - Dynamic Scaling Policies:
 * - Scale Out: Adds +1 instance when CPU >= 40%.
 * - Scale In: Removes -1 instance when CPU <= 10%.
 * - CloudWatch Alarms: Monitors CPU utilization to trigger scaling events.
 *
 * Key Features:
 * - Zero-Downtime Updates: Uses `create_before_destroy` lifecycle rules.
 * - Self-Healing: Automatically replaces unhealthy instances via ELB/EC2 health checks.
 */

locals {
  fe_asg_tags = merge(var.required_tags, { Name = "${var.lastname}-frontend-asg" })
  fe_lt_tags  = merge(var.required_tags, { Name = "${var.lastname}-frontend-lt" })
  be_asg_tags = merge(var.required_tags, { Name = "${var.lastname}-backend-asg" })
  be_lt_tags  = merge(var.required_tags, { Name = "${var.lastname}-backend-lt" })
}

# DATA SOURCES
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

# FRONTEND RESOURCES
# --- Frontend Launch Template ---
resource "aws_launch_template" "frontend_lt" {
  # makes names unique which prevents downtime during updates
  name_prefix            = "${var.lastname}-frontend-lt-"
  image_id               = data.aws_ami.latest_amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [var.frontend_sg_id]

  # Inject Backend URL variable into script
  user_data = base64encode(templatefile("${path.root}/scripts/frontend_userdata.sh", {
    BACKEND_URL = var.backend_url
  }))

  lifecycle {
    create_before_destroy = true
  }

  monitoring {
    # Enable detailed monitoring for better scaling responsiveness (1-minute metrics)
    # since cloudwatch default is 5 mins 
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.fe_asg_tags
  }
}

# --- Frontend Auto Scaling Group ---
resource "aws_autoscaling_group" "frontend_asg" {
  name                = "${var.lastname}-frontend-asg"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [var.frontend_tg_arn]

  health_check_type = "ELB"
  # might cause death loop when lowered; allows installation and updates before checking
  health_check_grace_period = 300
  # for tf to wait before marking instance as unhealthy; 10 mins default
  wait_for_capacity_timeout = "0"

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_size

  launch_template {
    id      = aws_launch_template.frontend_lt.id
    version = aws_launch_template.frontend_lt.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50  # Keep 50% of servers alive while updating
      instance_warmup        = 120 # Wait 2 mins before updating the next batch
    }
  }
  depends_on = [aws_launch_template.frontend_lt]
}

# BACKEND RESOURCES
# --- Backend Launch Template ---
resource "aws_launch_template" "backend_lt" {
  name_prefix   = "${var.lastname}-backend-lt-"
  image_id      = data.aws_ami.latest_amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [var.backend_sg_id]

  # Just read the file (no variables needed)
  user_data = base64encode(file("${path.root}/scripts/backend_userdata.sh"))

  lifecycle {
    create_before_destroy = true
  }

  monitoring {
    # Enable detailed monitoring for better scaling responsiveness (1-minute metrics)
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.be_asg_tags
  }
}

# --- Backend Auto Scaling Group ---
resource "aws_autoscaling_group" "backend_asg" {
  name                = "${var.lastname}-backend-asg"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [var.backend_tg_arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300
  wait_for_capacity_timeout = "0"

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_size

  launch_template {
    id      = aws_launch_template.backend_lt.id
    version = aws_launch_template.backend_lt.latest_version
  }
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50  # Keep 50% of servers alive while updating
      instance_warmup        = 300 # Wait 2 mins before updating the next batch
    }
  }
  depends_on = [aws_launch_template.backend_lt]
}

# FRONTEND SCALING POLICIES (Scaling Out & In)

# Scale OUT (Frontend)
resource "aws_autoscaling_policy" "frontend_scale_out" {
  name                   = "frontend-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60 #value for testing demo only; reset to 300
  autoscaling_group_name = aws_autoscaling_group.frontend_asg.name
}

resource "aws_cloudwatch_metric_alarm" "frontend_high_cpu" {
  alarm_name          = "${var.lastname}-frontend-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.period
  statistic           = "Average"
  threshold           = var.out_threshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.frontend_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.frontend_scale_out.arn]
}

# Scale IN (Frontend)
resource "aws_autoscaling_policy" "frontend_scale_in" {
  name                   = "frontend-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60 #value for testing demo only; reset to 300
  autoscaling_group_name = aws_autoscaling_group.frontend_asg.name
}

# should be slower then scale out to avoid flapping
resource "aws_cloudwatch_metric_alarm" "frontend_low_cpu" {
  alarm_name          = "${var.lastname}-frontend-low-cpu"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.period
  statistic           = "Average"
  threshold           = var.in_threshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.frontend_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.frontend_scale_in.arn]
}

# BACKEND SCALING POLICIES (Scaling Out & In)

# Scale OUT (Backend)
resource "aws_autoscaling_policy" "backend_scale_out" {
  name                   = "backend-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60 #value for testing demo only; reset to 300
  autoscaling_group_name = aws_autoscaling_group.backend_asg.name
}

resource "aws_cloudwatch_metric_alarm" "backend_high_cpu" {
  alarm_name          = "${var.lastname}-backend-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.period
  statistic           = "Average"
  threshold           = var.out_threshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.backend_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.backend_scale_out.arn]
}

# Scale IN (Backend)
resource "aws_autoscaling_policy" "backend_scale_in" {
  name                   = "backend-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60 #value for testing demo only; reset to 3000
  autoscaling_group_name = aws_autoscaling_group.backend_asg.name
}

resource "aws_cloudwatch_metric_alarm" "backend_low_cpu" {
  alarm_name          = "${var.lastname}-backend-low-cpu"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.period
  statistic           = "Average"
  threshold           = var.in_threshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.backend_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.backend_scale_in.arn]
}