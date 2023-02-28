# with minimal configurations
# aurora serverless --> Check for the modules 

module "aurora_mysql" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "7.6.2"

  name              = format("%s-%s-mysql", local.Environment, local.Name)
  engine            = "aurora-mysql"
  engine_mode       = "serverless"
  storage_encrypted = true

  create_random_password = false
  master_password        = var.master_password

  vpc_id                  = module.vpc.vpc_id
  subnets                 = module.vpc.database_subnets
  create_security_group   = false
  allowed_security_groups = [module.rds_aurora_sg.security_group_id]

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

module "rds_aurora_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.13"

  name        = format("%s_%s_rds_sg", local.Environment, local.Name)
  description = "Security group for Application Instances"
  vpc_id      = module.vpc.vpc_id
  computed_ingress_with_source_security_group_id = [
    {
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      description              = "RDS-APP Port"
      source_security_group_id = module.app_asg_sg.security_group_id
    },
    {
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      description              = "VPN Port"
      source_security_group_id = module.vpc.vpn_security_group
    },
  ]
  number_of_computed_ingress_with_source_security_group_id = 2
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

resource "null_resource" "db_setup" {
  depends_on = [module.aurora_mysql, module.rds_aurora_sg]
  provisioner "local-exec" {
    command = "sudo mysql --host=${module.aurora_mysql.cluster_endpoint} --port=3306 --user=root --password=Admin123 < ${file("${path.module}/schema.sql")}"
  }
}