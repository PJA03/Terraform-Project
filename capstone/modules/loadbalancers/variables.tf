variable "lastname" { type = string }
variable "required_tags" {
  type = map(string)
}
variable "vpc_id" { type = string }

# Subnets
variable "public_cidrs" { type = list(string) }
variable "private_cidrs" { type = list(string) }

# Security Group ( for the Application Load Balancer)
variable "alb_sg_id" {
  description = "Security Group for the Frontend ALB"
  type        = string
}

variable "health_check_path" {
  description = "The URL path for the health check (e.g., / or /health)"
  type        = string
  default     = "/"
}

variable "health_check_matcher" {
  description = "The HTTP codes to accept as healthy (e.g., 200 or 200-399)"
  type        = string
  default     = "200"
}

variable "tg_interval" {
  type    = number
  default = 30
}

variable "tg_timeout" {
  type    = number
  default = 5
}

variable "tg_healthy_threshold" {
  type    = number
  default = 2
}

variable "tg_unhealthy_threshold" {
  type    = number
  default = 2
}