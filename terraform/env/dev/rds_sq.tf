module "aurora" {
  source                           = "../../modules/terraform-aws-aurora-main"
  environment                      = "production"
  rds_instance_name                = "app-mysql"
  create_security_group            = true
  allowed_cidr_blocks              = []
  allowed_security_groups          = [module.rds-sg.security_group_id]
  engine                           = "aurora-mysql"
  engine_mode                      = "serverless"
  storage_encrypted                = true
  publicly_accessible              = false
  master_username                  = "produser"
  database_name                    = "proddb"
  port                             = 3306
  vpc_id                           = module.vpc.vpc_id
  subnets                          = module.vpc.database_subnets
  apply_immediately                = true
  create_random_password           = true
  skip_final_snapshot              = true
  final_snapshot_identifier_prefix = "prod-snapshot"
  snapshot_identifier              = null
  preferred_maintenance_window     = "Mon:00:00-Mon:03:00"
  preferred_backup_window          = "03:00-06:00"
  backup_retention_period          = 7
  enable_ssl_connection            = false
  family                           = "aurora-mysql5.7"
  autoscaling_enabled              = true
  autoscaling_max                  = 4
  autoscaling_min                  = 1
  predefined_metric_type           = "RDSReaderAverageDatabaseConnections"
  autoscaling_target_connections   = 40
  autoscaling_scale_in_cooldown    = 60
  autoscaling_scale_out_cooldown   = 30
  deletion_protection              = false
}

module "rds-sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.13"

  name        = format("%s-%s-sg", local.Environment, local.Name)
  description = "Security group for Application Instances"
  vpc_id      = module.vpc.vpc_id
  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "http port"
      cidr_blocks = "0.0.0.0/0"
    }
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
}