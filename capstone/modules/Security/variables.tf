variable "lastname" {
  type = string
}

variable "required_tags" {
  type = map(string)
}

variable "vpc_id" {
  description = "The ID of the VPC where security groups will be created"
  type        = string
}

variable "vpc_cidr" {
  type = string
}

variable "access_ip" {
  description = "IP address allowed to SSH into Bastion (e.g., your_public_ip/32)"
  type        = string
}

variable "http_port" {
  type = number
}

variable "ssh_port" {
  type = number
}
