variable "region" {
  type = string
}

variable "required_tags" {
  type = map(string)
}

variable "lastname" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_cidrs" {
  type = list(string)
}

variable "private_cidrs" {
  type = list(string)
}

variable "azs" {
  type = list(string)
}

# SG

variable "http_port" {
  type = number
}

variable "ssh_port" {
  type = number
}

# Bastion
variable "bastion_instance" {
  type = string
}

variable "key_name" {
  type = string
}

variable "assoc_ip" {
  type = bool
}
