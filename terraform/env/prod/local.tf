locals {

  Environment                = "prod"
  Name                       = "laravel"
  vpc_cidr                   = "172.10.0.0/16"
  app_image_id               = "ami-07388f7062e8065a9"
  worker_image_id            = "ami-092eaed4451c46845"
  instance_type              = "t3a.micro"
  image                      = "aws/codebuild/standard:2.0"
  type                       = "LINUX_CONTAINER"
  compute_platform           = "Server"
  group_name                 = "laravel"
  stream_name                = "laravel-instance"
  location                   = "https://github.com/chiragsquareops/HospitalMS"
  evaluation_periods         = "5"
  statistic_period           = "60"
  threshold                  = "50"
  threshold_unhealthy        = "0"
  output_artifacts           = "laravel_output"
  FullRepositoryId           = "chiragsquareops/HospitalMS"
  BranchName                 = "main"
  pipeline_name              = "laravel-app-pipeline"
  user_data_app              = <<EOF
#!/bin/bash -x
sudo systemctl restart codedeploy-agent.service
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:AmazonCloudWatch-linux
EOF
  user_data_worker           = <<EOF
#!/bin/bash -x
sudo systemctl restart codedeploy-agent.service
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:Queue-app-config
EOF
  ram_threshold_to_scale_out = 70
  ram_threshold_to_scale_in  = 30
  worker_threshold_scale_in  = 30
  worker_threshold_scale_out = 60

  zone_id      = "Z066794816K079BF0CQGU"
  host_headers = "myappvpn.labs.squareops.in"
  vpn_name     = "appvpn"
  domain_name  = "labs.squareops.in"
  zone_id_alb  = "Z35SXDOTRQ7X7K"
}