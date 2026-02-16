variable "lastname" { type = string }
variable "required_tags" {
  type = map(string)
}
variable "vpc_id" { type = string }

# Subnets
variable "public_cidrs" { type = list(string) }
variable "private_cidrs" { type = list(string) }

# Security Group (Only needed for the Application Load Balancer)
variable "alb_sg_id" {
  description = "Security Group for the Frontend ALB"
  type        = string
}