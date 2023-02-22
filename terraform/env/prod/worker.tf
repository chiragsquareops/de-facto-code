# ASG with scaling policies (Queue Based) --> Min Max size to be set as 1 in DEV || Scaling policies in prod
# CICD --> with Codepipeline
# S3 buckets --> To store artifacts (IAM Roles)
# Cloudwatch Alarms --> 


module "key_pair_worker_asg" {
  source             = "squareops/keypair/aws"
  environment        = local.Environment
  key_name           = format("%s_%s_worker_asg_kp", local.Environment, local.Name)
  ssm_parameter_path = format("%s_%s_worker_asg_kp", local.Environment, local.Name)
}

module "worker_asg_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.13"

  name        = format("%s_%s_worker_asg_sg", local.Environment, local.Name)
  description = "asg_sg"
  vpc_id      = module.vpc.vpc_id
  computed_ingress_with_source_security_group_id = [
    {
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      description              = "VPN Port"
      source_security_group_id = module.vpc.vpn_security_group
    },
  ]
  number_of_computed_ingress_with_source_security_group_id = 1
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

module "worker_asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "6.7.0"
  name    = format("%s_%s_worker_asg", local.Environment, local.Name)

  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  vpc_zone_identifier       = [element(module.vpc.private_subnets, 0), element(module.vpc.private_subnets, 1)]
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


  launch_template_name        = format("%s_%s_worker_lt", local.Environment, local.Name)
  launch_template_description = "Launch template for worker_app"
  update_default_version      = true

  image_id          = local.worker_image_id
  instance_type     = local.instance_type
  key_name          = module.key_pair_worker_asg.key_pair_name
  ebs_optimized     = false
  enable_monitoring = false
  security_groups   = [module.worker_asg_sg.security_group_id]
  user_data         = base64encode(local.user_data_worker)

  create_iam_instance_profile = true
  iam_role_name               = format("%s_%s_worker_instance_role", local.Environment, local.Name)
  iam_role_path               = "/ec2/"
  iam_role_description        = "IAM role for worker_instances"
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
}


resource "aws_autoscaling_policy" "asg_worker_SQS_scale_in_policy" {
  name                   = "${local.Name}_worker_SQS_scale_in_policy"
  autoscaling_group_name = module.worker_asg.autoscaling_group_name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

module "asg_worker_SQS_scale_in_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 3.0"

  alarm_name          = "${local.Name}_asg_worker_SQS_scale_in_alarm"
  alarm_description   = "worker_asg_scale_in_ram_alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = local.worker_threshold_scale_in
  period              = 60
  unit                = "Count"

  namespace   = "SQS"
  metric_name = "ApproximateNumberOfMessagesVisible"
  statistic   = "Average"

  alarm_actions = [resource.aws_autoscaling_policy.asg_worker_SQS_scale_in_policy.arn]
}

resource "aws_autoscaling_policy" "asg_worker_SQS_scale_out_policy" {
  name                   = "${local.Name}_worker_SQS_scale_out_policy"
  autoscaling_group_name = module.worker_asg.autoscaling_group_name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

module "asg_worker_SQS_scale_out_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 3.0"

  alarm_name          = "${local.Name}_asg_worker_SQS_scale_out_alarm"
  alarm_description   = "worker_asg_scale_out_SQS_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = local.worker_threshold_scale_out
  period              = 60
  unit                = "Count"

  namespace   = "SQS"
  metric_name = "ApproximateNumberOfMessagesVisible"
  statistic   = "Average"

  alarm_actions = [resource.aws_autoscaling_policy.asg_worker_SQS_scale_out_policy.arn]
}

resource "aws_iam_role" "worker_codebuild_role" {
  name = format("%s_%s_worker_codebuild_role", local.Environment, local.Name)

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

resource "aws_iam_role_policy" "worker_codebuild_policy" {
  role = aws_iam_role.worker_codebuild_role.name

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

resource "aws_codebuild_project" "worker" {
  name          = format("%s_%s_worker_codebuild_app", local.Environment, local.Name)
  description   = "worker_codebuild_project"
  build_timeout = "5"
  service_role  = aws_iam_role.worker_codebuild_role.arn

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

resource "aws_codedeploy_app" "worker" {
  compute_platform = local.compute_platform
  name             = format("%s_%s_worker_codedeploy_app", local.Environment, local.Name)
}

resource "aws_codedeploy_deployment_group" "worker_deploy_group" {
  app_name              = resource.aws_codedeploy_app.worker.name
  deployment_group_name = aws_codedeploy_app.worker.name
  service_role_arn      = resource.aws_iam_role.worker_codedeploy_role.arn
  autoscaling_groups    = [module.worker_asg.autoscaling_group_name]
}
resource "aws_iam_role" "worker_codedeploy_role" {
  name = format("%s_%s_worker_codedeploy_role", local.Environment, local.Name)

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

resource "aws_iam_role_policy" "worker_codedeploy_policy" {
  name = format("%s_%s_worker_codedeploy_policy", local.Environment, local.Name)
  role = aws_iam_role.worker_codedeploy_role.id

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

resource "aws_codepipeline" "worker_codepipeline" {
  name     = format("%s_%s_worker_codepipeline", local.Environment, local.Name)
  role_arn = aws_iam_role.worker_codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline-worker-bucket.bucket
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
        ConnectionArn    = aws_codestarconnections_connection.worker.arn
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
        ProjectName = format("%s_%s_codepipeline_project", local.Environment, local.Name)
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

resource "aws_codestarconnections_connection" "worker" {
  name          = format("%s_%s_codestarconnections", local.Environment, local.Name)
  provider_type = "GitHub"
}

resource "aws_s3_bucket" "codepipeline-worker-bucket" {
  bucket = format("%s-%s-codepipeline-worker-bucket", local.Environment, local.Name)
}

resource "aws_s3_bucket_acl" "codepipeline-worker-bucket-acl" {
  bucket = aws_s3_bucket.codepipeline-worker-bucket.id
  acl    = "private"
}



resource "aws_iam_role" "worker_codepipeline_role" {
  name = format("%s_%s_worker_codepipeline_role", local.Environment, local.Name)

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


resource "aws_iam_role_policy" "codepipeline_worker_policy" {
  name = format("%s_%s_worker_codepipeline_policy", local.Environment, local.Name)
  role = aws_iam_role.worker_codepipeline_role.id

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
				"${aws_s3_bucket.codepipeline-worker-bucket.arn}",
				"${aws_s3_bucket.codepipeline-worker-bucket.arn}/*"
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
