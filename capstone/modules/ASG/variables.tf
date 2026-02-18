variable "lastname" {
  type = string
}

variable "required_tags" {
  type = map(string)
}

variable "vpc_id" {
  type = string
}

variable "key_name" {
  type = string
}

# Security Groups 
variable "frontend_sg_id" {
  type = string
}

variable "backend_sg_id" {
  type = string
}

# Target Groups
variable "frontend_tg_arn" {
  type = string
}

variable "backend_tg_arn" {
  type = string
}

variable "backend_url" {
  description = "The DNS name of the Backend Load Balancer"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of Private Subnet IDs"
  type        = list(string)
}

variable "instance_type" {
  description = "Instance type"
  type        = string
}

variable "min_size" {
  description = "Minimum number of instances in the Auto Scaling Group"
  type = number
}

variable "max_size" {
  description = "Maximum number of instances in the Auto Scaling Group"
  type = number
}

variable "desired_size" {
  description = "Desired number of instances in the Auto Scaling Group"
  type = number
}

variable "evaluation_periods" {
  description = "Number of periods over which data is compared to the specified threshold"
  type        = number
}

variable "period" {
  type = number
}

variable "out_threshold" {
  type = number
}

variable "in_threshold" {
  type = number
}
