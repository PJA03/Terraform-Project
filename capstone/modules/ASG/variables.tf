# TAGGING
variable "lastname" {
  description = "Project prefix used for naming resources (e.g., 'Galias-FinalProject')"
  type        = string
}

variable "required_tags" {
  description = "A map of tags to assign to all resources (e.g., Owner, ProjectCode)"
  type        = map(string)
}


# NETWORK & SECURITY
variable "vpc_id" {
  description = "The ID of the VPC where resources will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of Private Subnet IDs for placing EC2 instances"
  type        = list(string)
}

variable "key_name" {
  description = "The name of the existing EC2 Key Pair for SSH access"
  type        = string
}

variable "frontend_sg_id" {
  description = "The Security Group ID to attach to Frontend instances"
  type        = string
}

variable "backend_sg_id" {
  description = "The Security Group ID to attach to Backend instances"
  type        = string
}

# LOAD BALANCING

variable "frontend_tg_arn" {
  description = "ARN of the Frontend Target Group (ALB)"
  type        = string
}

variable "backend_tg_arn" {
  description = "ARN of the Backend Target Group (NLB)"
  type        = string
}

variable "backend_url" {
  description = "DNS name (or endpoint) of the Backend Load Balancer, injected into Frontend User Data"
  type        = string
}

# AUTO SCALING GROUP (ASG) CONFIGURATION
variable "instance_type" {
  description = "The EC2 instance type to use for ASG instances (e.g., t3.micro)"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 4
}

variable "desired_size" {
  description = "Desired number of running instances in the ASG"
  type        = number
  default     = 2
}

# SCALING POLICIES (CLOUDWATCH ALARMS)
variable "evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold"
  type        = number
  default     = 1
}

variable "period" {
  description = "The period in seconds over which the specified statistic is applied"
  type        = number
  default     = 60
}

variable "out_threshold" {
  description = "The CPU percentage threshold to trigger a Scale Out (Add instance)"
  type        = number
  default     = 40
}

variable "in_threshold" {
  description = "The CPU percentage threshold to trigger a Scale In (Remove instance)"
  type        = number
  default     = 10
}