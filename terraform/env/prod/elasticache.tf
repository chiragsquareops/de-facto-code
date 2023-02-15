/* locals {
  name                 = "skaf"
  region               = "us-east-2"
  environment          = "production"
  redis_engine_version = "6.x"
}

module "redis" {
  source                     = "../../modules/terraform-aws-elasticache-redis-main"
  environment                = local.environment
  name                       = local.name
  engine_version             = local.redis_engine_version
  port                       = 6379
  node_type                  = "cache.t3.small"
  num_cache_nodes            = 2
  family                     = "redis6.x"
  availability_zones         = [for n in range(0, 2) : data.aws_availability_zones.available.names[n]]
  automatic_failover_enabled = true
  snapshot_retention_limit   = 7
  multi_az_enabled           = false
  at_rest_encryption_enabled = true
  transit_encryption_enabled = false
  notification_topic_arn     = null
  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.vpc.private_subnets
  allowed_cidr_blocks        = []
  allowed_security_groups    = [module.redis-sg.security_group_id]
  maintenance_window         = "sun:09:00-sun:10:00"
  snapshot_window            = "07:00-08:00"
  kms_key_arn                = "arn:aws:kms:us-east-1:309017165673:key/037b9bdc-5aa7-4b7d-908a-7b5c59157716"
}

module "redis-sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.13"

  name        = format("%s-%s-sg", local.Environment, local.Name)
  description = "Security group for Application Instances"
  vpc_id      = module.vpc.vpc_id
  ingress_with_cidr_blocks = [
    {
      from_port   = 6379
      to_port     = 6379
      protocol    = "tcp"
      description = "http port"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "outbound rule"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
} */