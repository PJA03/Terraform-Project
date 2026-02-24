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
  type        = number
  description = "The time in seconds between each health check ping sent to a target instance."
  default     = 30
}

variable "tg_timeout" {
  type        = number
  description = "The maximum time in seconds to wait for a response before marking a single health check attempt as failed."
  default     = 5
}

variable "tg_healthy_threshold" {
  type        = number
  description = "The number of consecutive successful health checks required to mark an unhealthy instance as healthy again."
  default     = 2
}

variable "tg_unhealthy_threshold" {
  type        = number
  description = "The number of consecutive failed health checks required to officially mark an instance as dead/unhealthy."
  default     = 2
}

variable "fe_lb_type" {
  type        = string
  description = "The type of load balancer for the frontend. 'application' (ALB) is used for Layer 7 HTTP/HTTPS traffic routing."
  default     = "application"
}

variable "be_lb_type" {
  type        = string
  description = "The type of load balancer for the backend. 'network' (NLB) is used for ultra-fast Layer 4 TCP traffic routing."
  default     = "network"
}