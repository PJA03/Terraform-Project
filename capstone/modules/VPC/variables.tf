# for tags
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

