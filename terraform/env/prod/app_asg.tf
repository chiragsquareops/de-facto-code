module "asg" {
  source = "../../modules/ASG"
  name   = format("%s-%s-asg", local.Environment, local.Name)

  min_size            = local.min_size
  max_size            = local.max_size
  desired_capacity    = local.desired_capacity
  health_check_type   = local.health_check_type_app
  vpc_zone_identifier = local.vpc_zone_identifier
  enabled_metrics     = local.enabled_metrics

  image_id                 = local.image_id
  instance_type            = local.instance_type
  key_name                 = local.key_name
  ebs_optimized            = false
  enable_monitoring        = false
  security_groups          = local.security_groups
  user_data                = base64encode(local.user_data)
  iam_instance_profile_arn = local.iam_instance_profile_arn

  asg_cpu_utilization_policy     = true
  asg_ALB_request_count_policy   = true
  asg_RAM_based_scale_out_policy = true
  asg_RAM_based_scale_in_policy  = true
  asg_queue_scale_in_policy      = false
  asg_queue_scale_out_policy     = false

  alb_enable       = true
  public_subnets   = local.public_subnets
  backend_port     = local.backend_port
  backend_protocol = local.backend_protocol
  target_type      = local.target_type
  certificate_arn  = local.certificate_arn

  tags = {
    Environment = local.Environment
    Name        = local.Name
    Owner       = local.Owner
  }
}
