module "vpc" {
  source = "./modules/vpc"
}

module "security" {
  source = "./modules/security"
  vpc_id = module.vpc.vpc_id
}

module "lb" {
  source         = "./modules/lb"
  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnets
  alb_sg_id      = module.security.alb_sg_id
}

module "rabbitmq" {
  source                = "./modules/rabbitmq"
  vpc_id                = module.vpc.vpc_id
  private_subnets       = module.vpc.private_subnets
  node_sg_id            = module.security.node_sg_id
  instance_profile_name = module.security.instance_profile_name
  target_group_arn      = module.lb.target_group_arn
  ami_id                = var.ami_id
}