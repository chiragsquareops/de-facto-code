# Keypairs module
# SG with modules 
# ASG with scaling policies --> (CPU, RAM, ALB request rate)
# ALB without access logs --> in dev. and In prod we will have access logs enabled bucket created, later the bucket can be moved to base folder.
# CICD --> with Codepipeline
# S3 buckets --> To store artifacts (IAM Roles)
# Cloudwatch Alarms --> 
# Route 53 Healthchecks --> 

module "key_pair_asg" {
  source             = "squareops/keypair/aws"
  environment        = local.Environment
  key_name           = format("%s-%s-asg", local.Environment, local.Name)
  ssm_parameter_path = format("%s-%s-asg", local.Environment, local.Name)
}


module "asg-sg" {

  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.13"

  name        = format("%s-%s-sg", local.Environment, local.Name)
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

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "6.7.0"
  name    = format("%s-%s-asg", local.Environment, local.Name)

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


  launch_template_name        = format("%s-%s-lt", local.Environment, local.Name)
  launch_template_description = "Launch template example"
  update_default_version      = true

  image_id          = "ami-07388f7062e8065a9"
  instance_type     = "t3a.micro"
  key_name          = module.key_pair_asg.key_pair_name
  ebs_optimized     = false
  enable_monitoring = false
  security_groups   = [module.asg-sg.security_group_id]
  user_data         = base64encode(local.user_data)

  create_iam_instance_profile = true
  iam_role_name               = format("%s-%s-instance-role", local.Environment, local.Name)
  iam_role_path               = "/ec2/"
  iam_role_description        = "IAM role example"
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

  scaling_policies = {
    asg-cpu-policy = {
      policy_type = "TargetTrackingScaling"
      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 50.0
      }
    }
    /* alb-request-rate-policy = {
      policy_type = "TargetTrackingScaling"
      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ALBRequestCountPerTarget"
          resource_label         = "testLabel"
        }
        target_value = 20.0
      }
    } */
  }
}




module "alb" {
  source             = "terraform-aws-modules/alb/aws"
  version            = "8.2.1"
  name               = format("%s-%s-alb", local.Environment, local.Name)
  load_balancer_type = "application"
  vpc_id             = module.vpc.vpc_id
  subnets            = [element(module.vpc.public_subnets, 0), element(module.vpc.public_subnets, 1)]
  security_groups    = [module.alb-sg.security_group_id]
  target_groups = [
    {
      name             = format("%s-%s-TG", local.Environment, local.Name)
      backend_protocol = "HTTP"
      backend_port     = 8000
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
      certificate_arn    = "arn:aws:acm:us-east-1:309017165673:certificate/721e3538-6f1a-4564-bc94-fb90b0b0d84d"
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

module "alb-sg" {

  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.13"

  name        = format("%s-%s-alb-sg", local.Environment, local.Name)
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

resource "aws_iam_role" "dev-app-role" {
  name = format("%s-%s-codebuild-role", local.Environment, local.Name)

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

resource "aws_iam_role_policy" "dev-app-policy" {
  role = aws_iam_role.dev-app-role.name

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:logs:us-east-1:421320058418:log-group:/aws/codebuild/${local.Name}",
                "arn:aws:logs:us-east-1:421320058418:log-group:/aws/codebuild/${local.Name}:*"
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
                "arn:aws:codebuild:us-east-1:421320058418:report-group/${local.Name}-*"
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
                "arn:aws:logs:us-east-1:421320058418:log-group:${local.group_name}",
                "arn:aws:logs:us-east-1:421320058418:log-group:${local.group_name}:*"
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

resource "aws_codebuild_project" "laravel-app" {
  name          = format("%s-%s-codebuild-app", local.Environment, local.Name)
  description   = "test_codebuild_project"
  build_timeout = "5"
  service_role  = aws_iam_role.dev-app-role.arn

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
    location        = local.Environment
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = true
    }
  }
}

resource "aws_codedeploy_app" "app" {
  compute_platform = local.compute_platform
  name             = format("%s-%s-codedeploy-app", local.Environment, local.Name)
}

resource "aws_codedeploy_deployment_group" "app-deploy-group" {
  app_name              = resource.aws_codedeploy_app.app.name
  deployment_group_name = aws_codedeploy_app.app.name
  service_role_arn      = resource.aws_iam_role.codedeploy_role.arn
  autoscaling_groups    = [module.asg.autoscaling_group_name]
}
resource "aws_iam_role" "codedeploy_role" {
  name = format("%s-%s-codedeploy-role", local.Environment, local.Name)

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
  name = format("%s-%s-codedeploy-policy", local.Environment, local.Name)
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
  name     = format("%s-%s-codepipeline", local.Environment, local.Name)
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
        ConnectionArn    = aws_codestarconnections_connection.example.arn
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

resource "aws_codestarconnections_connection" "example" {
  name          = format("%s-%s-codestarconnections", local.Environment, local.Name)
  provider_type = "GitHub"
}

resource "aws_s3_bucket" "codepipeline-bucket" {
  bucket = format("%s-%s-codepipeline-bucket", local.Environment, local.Name)
}

resource "aws_s3_bucket_acl" "codepipeline-bucket_acl" {
  bucket = aws_s3_bucket.codepipeline-bucket.id
  acl    = "private"
}



resource "aws_iam_role" "codepipeline_role" {
  name = format("%s-%s-codepipeline-role", local.Environment, local.Name)

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
  name = format("%s-%s-codepipeline-policy", local.Environment, local.Name)
  role = aws_iam_role.codepipeline_role.id

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
      "Effect": "Allow",
      "Action": [
        "codestar-connections:UseConnection"
      ],
      "Resource": "${aws_codestarconnections_connection.example.arn}"
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