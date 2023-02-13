module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = local.identifier

  engine            = local.engine
  engine_version    = local.engine_version
  instance_class    = local.instance_class
  allocated_storage = local.allocated_storage

  db_name  = local.db_name
  username = local.username
  port     = "3306"
  password = local.password

  vpc_security_group_ids = local.security_groups

  monitoring_interval    = "30"
  monitoring_role_name   = "LaravelMonitoringRole"
  create_monitoring_role = true

  create_db_subnet_group = true
  subnet_ids             = local.vpc_zone_identifier

  create_db_parameter_group = false

  create_db_option_group = false

  create_random_password = false

  family = "mysql5.7"

  major_engine_version = "5.7"

  deletion_protection = false

  tags = {
    Owner       = local.Owner
    Environment = local.Environment
    Name        = local.Name
    Terraform   = local.Terraform
  }
}

resource "aws_security_group" "laraveldb-sg" {
  name        = format("%s-%s--rds-sg", local.Environment, local.Name)
  description = "Allow TLS inbound and outbund traffic"
  vpc_id      = local.vpc_id
  dynamic "ingress" {
    for_each = [3306]
    iterator = port
    content {
      description = "TLS from vpc"
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Owner       = local.Owner
    Environment = local.Environment
    Name        = local.Name
    Terraform   = local.Terraform
  }
}