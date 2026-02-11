variable "lastname" { 
    type = string 
}

variable "required_tags" {
  type = map(string)
}

variable "vpc_id" { 
    type = string 
}

variable "private_cidrs" { 
    type = list(string) 
}

variable "key_name" { 
    type = string 
}

# Security Groups (passed from Security module)
variable "frontend_sg_id" { 
    type = string
}

variable "backend_sg_id" { 
    type = string 
}

# Target Groups (passed from LB module)
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