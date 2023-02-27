# Keypairs module
# SG with modules 
# ASG with scaling policies --> (CPU, RAM, ALB request rate)
# ALB without access logs --> in dev. and In prod we will have access logs enabled bucket created, later the bucket can be moved to base folder.
# CICD --> with Codepipeline
# S3 buckets --> To store artifacts (IAM Roles)
# Cloudwatch Alarms --> 
# Route 53 Healthchecks --> 
# app_ami_id --> called from local 

module "key_pair_app" {
  source             = "squareops/keypair/aws"
  environment        = local.Environment
  key_name           = format("%s_%s_app_asg_kp", local.Environment, local.Name)
  ssm_parameter_path = format("%s_%s_app_asg_kp", local.Environment, local.Name)
}

module "s3_bucket_alb_access_logs" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.7.0"

  bucket = "laravel-access-logs"
  acl    = "log-delivery-write"
  lifecycle_rule = [
    {
      id      = "monthly_retention"
      prefix  = "/"
      enabled = true

      expiration = {
        days = 10
      }
    }
  ]

  force_destroy = true

  attach_elb_log_delivery_policy = true
}

module "app_asg_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.13"

  name        = format("%s_%s_app_asg_sg", local.Environment, local.Name)
  description = "Security group for Application Instances"
  vpc_id      = module.vpc.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      description              = "ALB Port"
      source_security_group_id = module.app_alb_sg.security_group_id
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

module "app_asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "6.7.0"
  name    = format("%s_%s_app_asg", local.Environment, local.Name)

  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  vpc_zone_identifier       = [element(module.vpc.private_subnets, 0), element(module.vpc.private_subnets, 1)]
  target_group_arns         = [module.alb.target_group_arns[0]]
  enabled_metrics           = local.enabled_metrics
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


  launch_template_name        = format("%s_%s_app_lt", local.Environment, local.Name)
  launch_template_description = "Launch template for application"
  update_default_version      = true

  image_id          = local.app_image_id
  instance_type     = local.instance_type
  key_name          = module.key_pair_app.key_pair_name
  ebs_optimized     = false
  enable_monitoring = false
  security_groups   = [module.app_asg_sg.security_group_id]
  user_data         = base64encode(local.user_data_app)

  create_iam_instance_profile = true
  iam_role_name               = format("%s_%s_app_instance_role", local.Environment, local.Name)
  iam_role_path               = "/ec2/"
  iam_role_description        = "IAM role for application"
  iam_role_tags = {
    CustomIamRole = "Yes"
  }
  iam_role_policies = {
    AmazonSSMManagedInstanceCore  = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    AmazonEC2RoleforAWSCodeDeploy = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
    AWSCodeDeployRole             = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  }

  tags = {
    Environment = local.Environment
    Name        = local.Name
  }

  scaling_policies = {
    asg_cpu_policy = {
      policy_type               = "TargetTrackingScaling"
      estimated_instance_warmup = 120
      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 50.0
      }
    },
    request_count_per_target = {
      policy_type               = "TargetTrackingScaling"
      estimated_instance_warmup = 120
      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ALBRequestCountPerTarget"
          resource_label         = "${module.alb.lb_arn_suffix}/${module.alb.target_group_arn_suffixes[0]}"
        }
        target_value = 800
      }
    }
  }
}


resource "aws_autoscaling_policy" "app_asg_RAM_scale_out_policy" {
  name                   = "${local.Name}_app_asg_RAM_scale_out_policy"
  autoscaling_group_name = module.app_asg.autoscaling_group_name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

module "app_asg_ram_scale_out_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 3.0"

  alarm_name          = "${local.Name}_app_asg_RAM_scale_out_alarm"
  alarm_description   = "app_asg_scale_out_ram_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = local.ram_threshold_to_scale_out
  period              = 60
  unit                = "Count"

  namespace   = "laravel-app"
  metric_name = "mem_used_percent"
  statistic   = "Average"

  alarm_actions = [aws_autoscaling_policy.app_asg_RAM_scale_out_policy.arn]
}


resource "aws_autoscaling_policy" "app_asg_RAM_scale_in_policy" {
  name                   = "${local.Name}_app_asg_RAM_scale_in_policy"
  autoscaling_group_name = module.app_asg.autoscaling_group_name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

module "ram_metric_scale_in_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 3.0"

  alarm_name          = "${local.Name}_app_asg_RAM_scale_in_alarm"
  alarm_description   = "app_asg_scale_in_ram_alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = local.ram_threshold_to_scale_in
  period              = 60
  unit                = "Count"

  namespace   = "laravel-app"
  metric_name = "mem_used_percent"
  statistic   = "Average"

  alarm_actions = [resource.aws_autoscaling_policy.app_asg_RAM_scale_in_policy.arn]
}

module "alb" {
  source             = "terraform-aws-modules/alb/aws"
  version            = "8.2.1"
  name               = format("%s-%s-app-alb", local.Environment, local.Name)
  load_balancer_type = "application"
  vpc_id             = module.vpc.vpc_id
  subnets            = [element(module.vpc.public_subnets, 0), element(module.vpc.public_subnets, 1)]
  security_groups    = [module.app_alb_sg.security_group_id]

  access_logs = {
    bucket = "laravel-access-logs"
  }

  target_groups = [
    {
      name             = format("%s-%s-TG", local.Environment, local.Name)
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      health_check = {
        enabled             = true
        interval            = 10
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 2
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200"
      }
    }
  ]
  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = module.acm.acm_certificate_arn
      target_group_index = 0
    }
  ]
  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]
  tags = {
    Name        = local.Name
    Environment = local.Environment
  }
}

module "app_alb_sg" {

  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.13"

  name        = format("%s_%s_alb_sg", local.Environment, local.Name)
  description = "asg-sg"
  vpc_id      = module.vpc.vpc_id
  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "http port"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "https port"
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

resource "aws_iam_role" "codebuild_app_role" {
  name = format("%s_%s_app_codebuild_role", local.Environment, local.Name)

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codebuild_app_policy" {
  role = aws_iam_role.codebuild_app_role.name

  policy = <<POLICY
{
	"Version": "2012-10-17",
	"Statement": [{
			"Effect": "Allow",
			"Resource": "*",
			"Action": [
				"logs:CreateLogGroup",
				"logs:CreateLogStream",
				"logs:PutLogEvents"
			]
		},
		{
			"Effect": "Allow",
			"Resource": "*",
			"Action": [
				"s3:PutObject",
				"s3:GetObject",
				"s3:GetObjectVersion",
				"s3:GetBucketAcl",
				"s3:GetBucketLocation"
			]
		},
		{
			"Effect": "Allow",
			"Action": [
				"codebuild:CreateReportGroup",
				"codebuild:CreateReport",
				"codebuild:UpdateReport",
				"codebuild:BatchPutTestCases",
				"codebuild:BatchPutCodeCoverages"
			],
			"Resource": "*"
		},
		{
			"Sid": "VisualEditor0",
			"Effect": "Allow",
			"Action": [
				"secretsmanager:ListSecrets",
				"secretsmanager:GetSecretValue"
			],
			"Resource": "*"
		},
		{
			"Sid": "VisualEditor1",
			"Effect": "Allow",
			"Action": "secretsmanager:*",
			"Resource": "arn:aws:secretsmanager:us-east-1:421320058418:secret:/laravel-app/"
		},
		{
			"Effect": "Allow",
			"Resource": "*",
			"Action": [
				"logs:CreateLogGroup",
				"logs:CreateLogStream",
				"logs:PutLogEvents"
			]
		},
		{
			"Effect": "Allow",
			"Action": [
				"s3:*",
				"s3-object-lambda:*"
			],
			"Resource": "*"
		}
	]
}
POLICY
}

resource "aws_codebuild_project" "app" {
  name          = format("%s_%s_codebuild_app", local.Environment, local.Name)
  description   = "App_codebuild_project"
  build_timeout = "5"
  service_role  = aws_iam_role.codebuild_app_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = local.image
    type                        = local.type
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = local.group_name
      stream_name = local.stream_name
    }
  }

  source {
    type            = "GITHUB"
    location        = local.location
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = true
    }
  }
}

resource "aws_codedeploy_app" "app" {
  compute_platform = local.compute_platform
  name             = format("%s_%s_codedeploy_app", local.Environment, local.Name)
}

resource "aws_codedeploy_deployment_group" "app_deploy_group" {
  app_name              = resource.aws_codedeploy_app.app.name
  deployment_group_name = aws_codedeploy_app.app.name
  service_role_arn      = resource.aws_iam_role.codedeploy_role.arn
  autoscaling_groups    = [module.app_asg.autoscaling_group_name]
}
resource "aws_iam_role" "codedeploy_role" {
  name = format("%s_%s_codedeploy_role", local.Environment, local.Name)

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "codedeploy.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "codedeploy_policy" {
  name = format("%s_%s_app_codedeploy_policy", local.Environment, local.Name)
  role = aws_iam_role.codedeploy_role.id

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

resource "aws_codepipeline" "codepipeline" {
  name     = format("%s_%s_codepipeline_app", local.Environment, local.Name)
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline-bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = [local.output_artifacts]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.app.arn
        FullRepositoryId = local.FullRepositoryId
        BranchName       = local.BranchName
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = [local.output_artifacts]
      output_artifacts = ["${local.Name}_build_output"]
      version          = "1"

      configuration = {
        ProjectName = format("%s_%s_codebuild_app", local.Environment, local.Name)
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["${local.Name}_build_output"]
      version         = "1"

      configuration = {
        ApplicationName     = resource.aws_codedeploy_app.app.name
        DeploymentGroupName = resource.aws_codedeploy_deployment_group.app_deploy_group.deployment_group_name
      }
    }
  }
}

resource "aws_codestarconnections_connection" "app" {
  name          = format("%s_%s_codestarconnections", local.Environment, local.Name)
  provider_type = "GitHub"
}

resource "aws_s3_bucket" "codepipeline-bucket" {
  bucket = format("%s-%s-codepipeline-bucket", local.Environment, local.Name)
}

resource "aws_s3_bucket_acl" "codepipeline-bucket-acl" {
  bucket = aws_s3_bucket.codepipeline-bucket.id
  acl    = "private"
}



resource "aws_iam_role" "codepipeline_role" {
  name = format("%s_%s_app_codepipeline_role", local.Environment, local.Name)

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy" "codepipeline_policy" {
  name = format("%s_%s_app_codepipeline_policy", local.Environment, local.Name)
  role = aws_iam_role.codepipeline_role.id

  policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [{
			"Effect": "Allow",
			"Action": [
				"s3:GetObject",
				"s3:GetObjectVersion",
				"s3:GetBucketVersioning",
				"s3:PutObjectAcl",
				"s3:PutObject"
			],
			"Resource": [
				"${aws_s3_bucket.codepipeline-bucket.arn}",
				"${aws_s3_bucket.codepipeline-bucket.arn}/*"
			]
		},
		{
			"Action": [
				"iam:PassRole"
			],
			"Resource": "*",
			"Effect": "Allow",
			"Condition": {
				"StringEqualsIfExists": {
					"iam:PassedToService": [
						"cloudformation.amazonaws.com",
						"elasticbeanstalk.amazonaws.com",
						"ec2.amazonaws.com",
						"ecs-tasks.amazonaws.com"
					]
				}
			}
		},
		{
			"Action": [
				"codestar-connections:UseConnection"
			],
			"Resource": "*",
			"Effect": "Allow"
		},
		{
			"Action": [
				"codecommit:CancelUploadArchive",
				"codecommit:GetBranch",
				"codecommit:GetCommit",
				"codecommit:GetRepository",
				"codecommit:GetUploadArchiveStatus",
				"codecommit:UploadArchive"
			],
			"Resource": "*",
			"Effect": "Allow"
		},
		{
			"Effect": "Allow",
			"Action": [
				"codebuild:BatchGetBuilds",
				"codebuild:StartBuild"
			],
			"Resource": "*"
		},
		{
			"Effect": "Allow",
			"Action": [
				"devicefarm:ListProjects",
				"devicefarm:ListDevicePools",
				"devicefarm:GetRun",
				"devicefarm:GetUpload",
				"devicefarm:CreateUpload",
				"devicefarm:ScheduleRun"
			],
			"Resource": "*"
		},
		{
			"Effect": "Allow",
			"Action": [
				"servicecatalog:ListProvisioningArtifacts",
				"servicecatalog:CreateProvisioningArtifact",
				"servicecatalog:DescribeProvisioningArtifact",
				"servicecatalog:DeleteProvisioningArtifact",
				"servicecatalog:UpdateProduct"
			],
			"Resource": "*"
		},
		{
			"Action": [
				"codedeploy:*"
			],
			"Resource": "*",
			"Effect": "Allow"
		},
		{
			"Effect": "Allow",
			"Action": [
				"appconfig:StartDeployment",
				"appconfig:StopDeployment",
				"appconfig:GetDeployment"
			],
			"Resource": "*"
		}
	]
}
EOF
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name = "*.${local.domain_name}"
  zone_id     = local.zone_id

  subject_alternative_names = [
    "${local.Name}.${local.domain_name}",
    "${local.vpn_name}.${local.domain_name}",
  ]

  wait_for_validation = true

  tags = {
    Environment = local.Environment
    Name        = local.Name
  }
}

module "app_instance_records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 2.0"

  zone_id = local.zone_id

  records = [
    {
      name = "${local.Name}"
      type = "A"
      alias = {
        name                   = module.alb.lb_dns_name
        zone_id                = module.alb.lb_zone_id
        evaluate_target_health = true
      }
    },
  ]
}

module "vpn_records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 2.0"

  zone_id = local.zone_id

  records = [
    {
      name    = local.host_headers
      type    = "A"
      ttl     = 300
      records = [module.vpc.vpn_host_public_ip]
    }
  ]
}

module "rds_records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 2.0"

  zone_id = local.zone_id

  records = [
    {
      name    = local.rds_name 
      type    = "CNAME"
      ttl     = 300
      records = [module.aurora_mysql.cluster_endpoint]
    }
  ]
}
