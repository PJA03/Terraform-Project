locals {
  app_tiers = {
    frontend = {
      sg_id     = var.frontend_sg_id
      tg_arn    = var.frontend_tg_arn
      user_data = "${path.root}/scripts/frontend_userdata.sh" 
      tags      = merge(var.required_tags, { Name = "${var.lastname}-frontend-asg" })
    }
    backend = {
      sg_id     = var.backend_sg_id
      tg_arn    = var.backend_tg_arn
      user_data = "${path.root}/scripts/backend_userdata.sh"
      tags      = merge(var.required_tags, { Name = "${var.lastname}-backend-asg" })
    }
  }
}

# Get Latest Amazon Linux 2023 AMI
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

# Launch Templates (Created for both end) 
# TODO: Fix this
resource "aws_launch_template" "app_lt" {
  for_each = local.app_tiers

  name_prefix   = "${var.lastname}-${each.key}-lt-"
  image_id      = data.aws_ami.latest_amazon_linux.id
  instance_type = "t3.micro"
  key_name      = var.key_name

  vpc_security_group_ids = [each.value.sg_id]

  # Logic: If this is the "frontend", use templatefile with the variable.
  #        If this is the "backend", just read the file normally.
  user_data = each.key == "frontend" ? base64encode(templatefile("${path.root}/scripts/frontend_userdata.sh", {
    # If the script asks for lowercase:
    backend_url = var.backend_url
    # If the script asks for UPPERCASE:
    BACKEND_URL = var.backend_url
  })) : base64encode(file("${path.root}/scripts/backend_userdata.sh"))
  tag_specifications {
    resource_type = "instance"
    tags = each.value.tags
  }
}

# Auto Scaling Groups for both ends
resource "aws_autoscaling_group" "app_asg" {
  for_each = local.app_tiers

  name                = "${var.lastname}-${each.key}-asg"
  vpc_zone_identifier = var.private_cidrs
  target_group_arns   = [each.value.tg_arn]
  
  # Health Checks
  health_check_type         = "ELB"
  health_check_grace_period = 300

  # Capacity
  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.app_lt[each.key].id
    version = "$Latest"
  }
}

# SCALE OUT RULES (CPU >= 40%)
resource "aws_autoscaling_policy" "scale_out" {
  for_each = local.app_tiers

  name                   = "${each.key}-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app_asg[each.key].name
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  for_each = local.app_tiers

  alarm_name          = "${var.lastname}-${each.key}-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 40

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg[each.key].name
  }

  alarm_actions = [aws_autoscaling_policy.scale_out[each.key].arn]
}

# SCALE IN RULES (CPU <= 10%)
resource "aws_autoscaling_policy" "scale_in" {
  for_each = local.app_tiers

  name                   = "${each.key}-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app_asg[each.key].name
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  for_each = local.app_tiers

  alarm_name          = "${var.lastname}-${each.key}-low-cpu"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 10

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg[each.key].name
  }

  alarm_actions = [aws_autoscaling_policy.scale_in[each.key].arn]
}