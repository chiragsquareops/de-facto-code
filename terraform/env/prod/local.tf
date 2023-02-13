locals {
  instance-size                 = "t3a.micro"
  cidr                          = "10.0.0.0/16"
  ami                           = "ami-0778521d914d23bc1"
  Environment                   = "prod"
  Terraform                     = "true"
  Owner                         = "Chirag-SquareOps"
  identifier                    = "laravel"
  engine                        = "mysql"
  engine_version                = "5.7.33"
  instance_class                = "db.t3.micro"
  db_name                       = "laravel"
  username                      = "root"
  password                      = "Admin123"
  name_prefix                   = "main"
  allocated_storage             = "5"
  min_size                      = "1"
  max_size                      = "1"
  desired_capacity              = "1"
  image_id                      = "ami-07388f7062e8065a9"
  instance_type                 = "t3a.micro"
  key_name                      = "laravel-application"
  environment                   = "dev"
  terraform                     = "true"
  owner                         = "Chirag-SquareOps"
  Name                          = "laravel-app"
  region                        = "us-east-1"
  image                         = "aws/codebuild/standard:2.0"
  type                          = "LINUX_CONTAINER"
  compute_platform              = "Server"
  group_name                    = "laravel"
  stream_name                   = "laravel-instance"
  location                      = "https://github.com/chiragsquareops/HospitalMS"
  domain_name                   = "rtd.squareops.co.in"
  evaluation_periods            = "5"
  statistic_period              = "60"
  threshold                     = "50"
  threshold_unhealthy           = "0"
  output_artifacts              = "laravel_output"
  FullRepositoryId              = "chiragsquareops/HospitalMS"
  BranchName                    = "main"
  pipeline_name                 = "laravel-app-pipeline"
  user_data                     = <<EOF
#!/bin/bash -x
sudo systemctl restart codedeploy-agent.service
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:AmazonCloudWatch-linux
EOF
  threshold_to_scale_out        = 70
  threshold_to_scale_in         = 30
  cpu_value_threshold           = 80
  request_count_value_threshold = 20
  queue_threshold_scale_in      = 30
  queue_threshold_scale_out     = 60
  iam_instance_profile_arn      = "arn:aws:iam::309017165673:instance-profile/chirag-codedeploy-cloudwatch"
  vpc_id                        = "vpc-00dd3f4de32c1808f"
  backend_port                  = 8000
  backend_protocol              = "HTTP"
  target_type                   = "instance"
  certificate_arn               = "arn:aws:acm:us-east-1:309017165673:certificate/721e3538-6f1a-4564-bc94-fb90b0b0d84d"
  vpc_zone_identifier           = ["subnet-06b63d7e874ff5dc1", "subnet-0a067da4dd10dd6eb"]
  enabled_metrics               = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
  security_groups               = ["sg-0e180ed023f129662", "sg-0c1aca5205c0c92e2"]
  public_subnets                = ["subnet-06b63d7e874ff5dc1", "subnet-0a067da4dd10dd6eb"]
  health_check_type_app         = "ELB"
  wait_for_capacity_timeout     = 0
  health_check_type_queue       = "EC2"
}
