# with minimal configurations
# aurora serverless --> Check for the modules 

module "aurora_mysql" {
  source = "terraform-aws-modules/rds-aurora/aws"

  name              = format("%s-%s-mysql", local.Environment, local.Name)
  engine            = "aurora-mysql"
  engine_mode       = "serverless"
  storage_encrypted = true

  vpc_id                = module.vpc.vpc_id
  subnets               = module.vpc.database_subnets
  create_security_group = true

  monitoring_interval = 60

  apply_immediately   = true
  skip_final_snapshot = true

  db_parameter_group_name         = aws_db_parameter_group.aurora_db_mysql.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_db_mysql.id

  scaling_configuration = {
    auto_pause               = true
    min_capacity             = 2
    max_capacity             = 16
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }
}

resource "aws_db_parameter_group" "aurora_db_mysql" {
  name        = "${local.Name}-aurora-db-mysql-parameter-group"
  family      = "aurora-mysql5.7"
  description = "${local.Name}-aurora-db-mysql-parameter-group"
  tags = {
    Environment = local.Environment
    Name        = local.Name
  }
}

resource "aws_rds_cluster_parameter_group" "aurora_db_mysql" {
  name        = "${local.Name}-aurora-mysql-cluster-parameter-group"
  family      = "aurora-mysql5.7"
  description = "${local.Name}-aurora-mysql-cluster-parameter-group"
  tags = {
    Environment = local.Environment
    Name        = local.Name
  }
}
