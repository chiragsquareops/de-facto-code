# ASG with scaling policies (Queue Based) --> Min Max size to be set as 1 in DEV || Scaling policies in prod
# CICD --> with Codepipeline
# S3 buckets --> To store artifacts (IAM Roles)
# Cloudwatch Alarms --> 


module "key_pair_worker_asg" {
  source             = "squareops/keypair/aws"
  environment        = local.Environment
  key_name           = format("%s-%s-worker-asg", local.Environment, local.Name)
  ssm_parameter_path = format("%s-%s-worker-asg", local.Environment, local.Name)
}

module "worker-asg-sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.13"

  name        = format("%s-%s-worker-asg-sg", local.Environment, local.Name)
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

module "worker-asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "6.7.0"
  name    = format("%s-%s-worker-asg", local.Environment, local.Name)

  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  vpc_zone_identifier       = [module.vpc.public_subnets[0]]
  target_group_arns         = [module.alb.target_group_arns[0]]
  enabled_metrics           = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]

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


  launch_template_name        = format("%s-%s-worker-lt", local.Environment, local.Name)
  launch_template_description = "Launch template for worker-app"
  update_default_version      = true

  image_id          = "ami-07388f7062e8065a9"
  instance_type     = "t3a.micro"
  key_name          = module.key_pair_asg.key_pair_name
  ebs_optimized     = false
  enable_monitoring = false
  security_groups   = [module.asg-sg.security_group_id]
  user_data         = base64encode(local.user_data)

  create_iam_instance_profile = true
  iam_role_name               = format("%s-%s-worker-instance-role", local.Environment, local.Name)
  iam_role_path               = "/ec2/"
  iam_role_description        = "IAM role for worker-instances"
  iam_role_tags = {
    CustomIamRole = "Yes"
  }
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = {
    Environment = local.Environment
    Name        = local.Name
  }
}


resource "aws_autoscaling_policy" "asg_worker_scale_in" {
  name                   = "${local.Name}-scale-in-policy"
  autoscaling_group_name = module.worker-asg.autoscaling_group_name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

module "worker_metric_scale_in_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 3.0"

  alarm_name          = "${local.Name}-worker-asg-scale-in-alarm"
  alarm_description   = "worker-asg-scale-in-ram-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = local.worker_threshold_scale_in
  period              = 60
  unit                = "Count"

  namespace   = "SQS"
  metric_name = "ApproximateNumberOfMessagesVisible"
  statistic   = "Average"

  alarm_actions = [resource.aws_autoscaling_policy.asg_worker_scale_in.arn]
}

resource "aws_autoscaling_policy" "asg_worker_scale_out" {
  name                   = "${local.Name}-scale-out-policy"
  autoscaling_group_name = module.worker-asg.autoscaling_group_name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

module "worker_metric_scale_out_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 3.0"

  alarm_name          = "${local.Name}-worker-asg-scale-out-alarm"
  alarm_description   = "worker-asg-scale-out-ram-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = local.worker_threshold_scale_out
  period              = 60
  unit                = "Count"

  namespace   = "SQS"
  metric_name = "ApproximateNumberOfMessagesVisible"
  statistic   = "Average"

  alarm_actions = [resource.aws_autoscaling_policy.asg_worker_scale_out.arn]
}

resource "aws_iam_role" "worker-codebuild-role" {
  name = format("%s-%s-worker-codebuild-role", local.Environment, local.Name)

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

resource "aws_iam_role_policy" "worker-codebuild-policy" {
  role = aws_iam_role.worker-codebuild-role.name

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:logs:us-east-1:421320058418:log-group:/aws/codebuild/${local.Name}-worker",
                "arn:aws:logs:us-east-1:421320058418:log-group:/aws/codebuild/${local.Name}-worker:*"
            ],
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::codepipeline-us-east-1-*"
            ],
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
            "Resource": [
                "arn:aws:codebuild:us-east-1:421320058418:report-group/${local.Name}-worker-*"
            ]
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
            "Resource": [
                "arn:aws:logs:us-east-1:421320058418:log-group:${local.group_name}-worker",
                "arn:aws:logs:us-east-1:421320058418:log-group:${local.group_name}-worker:*"
            ],
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
  name          = format("%s-%s-worker-codebuild-app", local.Environment, local.Name)
  description   = "worker_codebuild_project"
  build_timeout = "5"
  service_role  = aws_iam_role.worker-codebuild-role.arn

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
  name             = format("%s-%s-worker-codedeploy-app", local.Environment, local.Name)
}

resource "aws_codedeploy_deployment_group" "worker-deploy-group" {
  app_name              = resource.aws_codedeploy_app.worker.name
  deployment_group_name = aws_codedeploy_app.worker.name
  service_role_arn      = resource.aws_iam_role.worker_codedeploy_role.arn
  autoscaling_groups    = [module.worker-asg.autoscaling_group_name]
}
resource "aws_iam_role" "worker_codedeploy_role" {
  name = format("%s-%s-worker-codedeploy-role", local.Environment, local.Name)

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
  name = format("%s-%s-worker-codedeploy-policy", local.Environment, local.Name)
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
  name     = format("%s-%s-worker-codepipeline", local.Environment, local.Name)
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
        ProjectName = format("%s-%s-codepipeline-project", local.Environment, local.Name)
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
        DeploymentGroupName = resource.aws_codedeploy_deployment_group.app-deploy-group.deployment_group_name
      }
    }
  }
}

resource "aws_codestarconnections_connection" "worker" {
  name          = format("%s-%s-codestarconnections", local.Environment, local.Name)
  provider_type = "GitHub"
}

resource "aws_s3_bucket" "codepipeline-worker-bucket" {
  bucket = format("%s-%s-codepipeline-worker-bucket", local.Environment, local.Name)
}

resource "aws_s3_bucket_acl" "codepipeline-worker-bucket_acl" {
  bucket = aws_s3_bucket.codepipeline-worker-bucket.id
  acl    = "private"
}



resource "aws_iam_role" "worker_codepipeline_role" {
  name = format("%s-%s-worker-codepipeline-role", local.Environment, local.Name)

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
  name = format("%s-%s-worker-codepipeline-policy", local.Environment, local.Name)
  role = aws_iam_role.worker_codepipeline_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
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
      "Effect": "Allow",
      "Action": [
        "codestar-connections:UseConnection"
      ],
      "Resource": "${aws_codestarconnections_connection.worker.arn}"
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
                "codedeploy:CreateDeployment",
                "codedeploy:GetApplication",
                "codedeploy:GetApplicationRevision",
                "codedeploy:GetDeployment",
                "codedeploy:GetDeploymentConfig",
                "codedeploy:RegisterApplicationRevision"
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
