data "aws_availability_zones" "available" {}

module "key_pair_vpn" {
  source             = "squareops/keypair/aws"
  environment        = local.Environment
  key_name           = format("%s_%s_vpn_kp", local.Environment, local.Name)
  ssm_parameter_path = format("%s_%s_vpn_kp", local.Environment, local.Name)
}

module "vpc" {
  source                                          = "squareops/vpc/aws"
  environment                                     = local.Environment
  name                                            = local.Name
  vpc_cidr                                        = local.vpc_cidr
  azs                                             = [for n in range(0, 2) : data.aws_availability_zones.available.names[n]]
  enable_public_subnet                            = true
  enable_private_subnet                           = true
  enable_database_subnet                          = true
  enable_intra_subnet                             = false
  one_nat_gateway_per_az                          = false
  vpn_server_enabled                              = true
  vpn_server_instance_type                        = "t3a.micro"
  vpn_key_pair                                    = module.key_pair_vpn.key_pair_name
  enable_flow_log                                 = false
  flow_log_max_aggregation_interval               = 60
  flow_log_cloudwatch_log_group_retention_in_days = 90
}