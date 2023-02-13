locals {
  region      = "us-east-1"
  Environment = "test"
  tags = {
    Automation  = "true"
    Environment = local.Environment
  }
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "6.7.0"
  name    = "${var.name}-asg"

  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  wait_for_capacity_timeout = var.wait_for_capacity_timeout
  health_check_type         = var.health_check_type
  vpc_zone_identifier       = var.vpc_zone_identifier
  target_group_arns         = var.alb_enable ? module.alb[0].target_group_arns : null
  enabled_metrics           = var.enabled_metrics

  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      checkpoint_delay       = 60
      checkpoint_percentages = [35, 70, 100]
      instance_warmup        = 300
      min_healthy_percentage = 50
    }
    triggers = ["tag"]
  }


  launch_template_name        = "${var.name}-lt"
  launch_template_description = "Launch template example"
  update_default_version      = true

  image_id                 = var.image_id
  instance_type            = var.instance_type
  key_name                 = var.key_name
  ebs_optimized            = var.ebs_optimized
  enable_monitoring        = var.enable_monitoring
  security_groups          = var.security_groups
  user_data                = base64encode(var.user_data)
  iam_instance_profile_arn = var.iam_instance_profile_arn

  tags = {
    Environment = var.Environment
    Owner       = var.Owner
  }
}



resource "aws_autoscaling_policy" "asg_cpu_utilization_policy" {
  count                     = var.asg_cpu_utilization_policy ? 1 : 0
  name                      = "${var.name}-cpu-policy"
  autoscaling_group_name    = module.asg.autoscaling_group_name
  estimated_instance_warmup = 60
  policy_type               = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_value_threshold
  }
}

resource "aws_autoscaling_policy" "asg_ALB_request_count_policy" {
  count                     = var.asg_ALB_request_count_policy ? 1 : 0
  name                      = "${var.name}-cpu-policy"
  autoscaling_group_name    = module.asg.autoscaling_group_name
  estimated_instance_warmup = 60
  policy_type               = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
    }
    target_value = var.request_count_value_threshold
  }
}


resource "aws_autoscaling_policy" "RAM_based_scale_out" {
  count                  = var.asg_RAM_based_scale_out_policy ? 1 : 0
  name                   = "${var.name}-asg-RAM-scale-out-policy"
  autoscaling_group_name = module.asg.autoscaling_group_name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "RAM_based_scale_out_alarm" {
  count               = var.asg_RAM_based_scale_out_policy ? 1 : 0
  alarm_name          = "${var.name}-asg-scale-out-alarm"
  alarm_description   = "asg-scale-out-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "mem_used_percent"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = var.threshold_to_scale_out
  dimensions = {
    "AutoScalingGroupName" = module.asg.autoscaling_group_name
  }
  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.RAM_based_scale_out[0].arn]
  depends_on      = [aws_autoscaling_policy.RAM_based_scale_out]
}

resource "aws_autoscaling_policy" "RAM_based_scale_in" {
  count                  = var.asg_RAM_based_scale_in_policy ? 1 : 0
  name                   = "${var.name}-asg-RAM-scale-in-policy"
  autoscaling_group_name = module.asg.autoscaling_group_name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "RAM_based_scale_in_alarm" {
  count               = var.asg_RAM_based_scale_in_policy ? 1 : 0
  alarm_name          = "${var.name}-asg-scale-in-alarm"
  alarm_description   = "asg-scale-in-cpu-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "mem_used_percent"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = var.threshold_to_scale_in
  dimensions = {
    "AutoScalingGroupName" = module.asg.autoscaling_group_name
  }
  actions_enabled = true
  alarm_actions   = [resource.aws_autoscaling_policy.RAM_based_scale_in[0].arn]
  depends_on = [
    aws_autoscaling_policy.RAM_based_scale_in
  ]
}

resource "aws_autoscaling_policy" "asg_queue_scale_in" {
  count                  = var.asg_queue_scale_in_policy ? 1 : 0
  name                   = "${var.name}-scale-in-policy"
  autoscaling_group_name = module.asg.autoscaling_group_name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "asg_queue_scale_in_alarm" {
  count               = var.asg_queue_scale_in_policy ? 1 : 0
  alarm_name          = "${var.name}-queue-asg-scale-in-alarm"
  alarm_description   = "asg-scale-in-cpu-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "SQS"
  period              = "120"
  statistic           = "Average"
  threshold           = var.queue_threshold_scale_in
  dimensions = {
    "AutoScalingGroupName" = module.asg.autoscaling_group_name
  }
  actions_enabled = true
  alarm_actions   = [resource.aws_autoscaling_policy.asg_queue_scale_in[0].arn]
  depends_on = [
    aws_autoscaling_policy.asg_queue_scale_in
  ]
}

resource "aws_autoscaling_policy" "asg_queue_scale_out" {
  count                  = var.asg_queue_scale_out_policy ? 1 : 0
  name                   = "${var.name}-scale-out-policy"
  autoscaling_group_name = module.asg.autoscaling_group_name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "asg_queue_scale_out_alarm" {
  count               = var.asg_queue_scale_out_policy ? 1 : 0
  alarm_name          = "${var.name}-scale-out-alarm"
  alarm_description   = "asg-scale-out-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "SQS"
  period              = "120"
  statistic           = "Average"
  threshold           = var.queue_threshold_scale_out
  dimensions = {
    "AutoScalingGroupName" = module.asg.autoscaling_group_name
  }
  actions_enabled = true
  alarm_actions   = [resource.aws_autoscaling_policy.asg_queue_scale_out[0].arn]
  depends_on = [
    aws_autoscaling_policy.asg_queue_scale_in
  ]
}


resource "aws_security_group" "asg-sg" {
  name        = "${var.name}-asg-sg"
  description = "Allow TLS inbound and outbund traffic"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = [22, 8000]
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
    name        = "${var.name}-sg-node"
    Owner       = var.Owner
    Environment = var.Environment
    Terraform   = var.Terraform
  }
}

resource "aws_iam_role" "instance-role" {
  name = "${var.name}-instance-profile"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ssm-policy" {
  role       = aws_iam_role.instance-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_iam_role_policy_attachment" "cloudwatch-asg" {
  role       = aws_iam_role.instance-role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy" "instance-profile" {
  name = "${var.name}-deploy-policy"
  role = aws_iam_role.instance-role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:CompleteLifecycleAction",
                "autoscaling:DeleteLifecycleHook",
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeLifecycleHooks",
                "autoscaling:PutLifecycleHook",
                "autoscaling:RecordLifecycleActionHeartbeat",
                "autoscaling:CreateAutoScalingGroup",
                "autoscaling:UpdateAutoScalingGroup",
                "autoscaling:EnableMetricsCollection",
                "autoscaling:DescribePolicies",
                "autoscaling:DescribeScheduledActions",
                "autoscaling:DescribeNotificationConfigurations",
                "autoscaling:SuspendProcesses",
                "autoscaling:ResumeProcesses",
                "autoscaling:AttachLoadBalancers",
                "autoscaling:AttachLoadBalancerTargetGroups",
                "autoscaling:PutScalingPolicy",
                "autoscaling:PutScheduledUpdateGroupAction",
                "autoscaling:PutNotificationConfiguration",
                "autoscaling:PutWarmPool",
                "autoscaling:DescribeScalingActivities",
                "autoscaling:DeleteAutoScalingGroup",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus",
                "ec2:TerminateInstances",
                "tag:GetResources",
                "sns:Publish",
                "cloudwatch:DescribeAlarms",
                "cloudwatch:PutMetricAlarm",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeInstanceHealth",
                "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
                "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:DescribeTargetHealth",
                "elasticloadbalancing:RegisterTargets",
                "elasticloadbalancing:DeregisterTargets"
            ],
            "Resource": "*"
        },
       {
            "Effect": "Allow",
            "Action": [
                "s3:*",
                "s3-object-lambda:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "iam:PassRole",
                "ec2:CreateTags",
                "ec2:RunInstances"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}


