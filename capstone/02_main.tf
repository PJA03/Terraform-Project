module "network" {
  source        = "./modules/VPC"
  lastname      = var.lastname
  required_tags = var.required_tags
}

# for dynamically getting my ip
data "http" "my_ip" {
  url = "http://ipv4.icanhazip.com"
}

module "security" {
  source        = "./modules/security"
  vpc_id        = module.network.vpc_id
  lastname      = var.lastname
  required_tags = var.required_tags

  #   chomp for clean up
  access_ip = "${chomp(data.http.my_ip.response_body)}/32"
}

module "bastion_host" {
  source         = "./modules/Bastion"
  lastname       = var.lastname
  required_tags  = var.required_tags
  key_name       = var.key_name
  public_subnets = module.network.public_subnet_ids
  bastion_sg_id  = module.security.bastion_sg_id
}

# asg module
module "instances" {
  source             = "./modules/ASG"
  lastname           = var.lastname
  required_tags      = var.required_tags
  key_name           = var.key_name
  vpc_id             = module.network.vpc_id
  frontend_sg_id     = module.security.frontend_sg_id
  backend_sg_id      = module.security.backend_sg_id
  frontend_tg_arn    = module.loadbalancers.frontend_tg_arn
  backend_tg_arn     = module.loadbalancers.backend_tg_arn
  backend_url        = module.loadbalancers.backend_dns_name
  private_subnet_ids = module.network.private_subnet_ids
}

module "loadbalancers" {
  source        = "./modules/loadbalancers"
  lastname      = var.lastname
  required_tags = var.required_tags
  vpc_id        = module.network.vpc_id
  public_cidrs  = module.network.public_subnet_ids
  private_cidrs = module.network.private_subnet_ids
  alb_sg_id     = module.security.alb_sg_id
}