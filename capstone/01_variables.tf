variable "region" {
  type = string
}

variable "required_tags" {
  type = map(string)
}

variable "lastname" {
  type = string
}

# Bastion

variable "key_name" {
  type = string
}