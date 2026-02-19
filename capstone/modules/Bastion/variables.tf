variable "lastname" {
  type = string
}

variable "required_tags" {
  type = map(string)
}

variable "bastion_instance" {
  type    = string
  default = "t2.micro"
}

variable "key_name" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "assoc_ip" {
  type    = bool
  default = true
}

variable "bastion_sg_id" {
  type = string
}