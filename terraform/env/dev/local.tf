locals {

  Environment         = "dev"
  Name                = "app"
  image               = "aws/codebuild/standard:2.0"
  type                = "LINUX_CONTAINER"
  compute_platform    = "Server"
  group_name          = "laravel"
  stream_name         = "laravel-instance"
  location            = "https://github.com/chiragsquareops/HospitalMS"
  domain_name         = "rtd.squareops.co.in"
  evaluation_periods  = "5"
  statistic_period    = "60"
  threshold           = "50"
  threshold_unhealthy = "0"
  output_artifacts    = "laravel_output"
  FullRepositoryId    = "chiragsquareops/HospitalMS"
  BranchName          = "main"
  pipeline_name       = "laravel-app-pipeline"
  user_data           = <<EOF
#!/bin/bash -x
sudo systemctl restart codedeploy-agent.service
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:AmazonCloudWatch-linux
EOF
}