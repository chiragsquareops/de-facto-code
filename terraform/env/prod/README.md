<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.56.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_acm"></a> [acm](#module\_acm) | terraform-aws-modules/acm/aws | ~> 4.0 |
| <a name="module_alb"></a> [alb](#module\_alb) | terraform-aws-modules/alb/aws | 8.2.1 |
| <a name="module_app_alb_sg"></a> [app\_alb\_sg](#module\_app\_alb\_sg) | terraform-aws-modules/security-group/aws | ~> 4.13 |
| <a name="module_app_asg"></a> [app\_asg](#module\_app\_asg) | terraform-aws-modules/autoscaling/aws | 6.7.0 |
| <a name="module_app_asg_ram_scale_out_alarm"></a> [app\_asg\_ram\_scale\_out\_alarm](#module\_app\_asg\_ram\_scale\_out\_alarm) | terraform-aws-modules/cloudwatch/aws//modules/metric-alarm | ~> 3.0 |
| <a name="module_app_asg_sg"></a> [app\_asg\_sg](#module\_app\_asg\_sg) | terraform-aws-modules/security-group/aws | ~> 4.13 |
| <a name="module_app_instance_records"></a> [app\_instance\_records](#module\_app\_instance\_records) | terraform-aws-modules/route53/aws//modules/records | ~> 2.0 |
| <a name="module_aurora_mysql"></a> [aurora\_mysql](#module\_aurora\_mysql) | terraform-aws-modules/rds-aurora/aws | 7.6.2 |
| <a name="module_key_pair_app"></a> [key\_pair\_app](#module\_key\_pair\_app) | squareops/keypair/aws | n/a |
| <a name="module_key_pair_vpn"></a> [key\_pair\_vpn](#module\_key\_pair\_vpn) | squareops/keypair/aws | n/a |
| <a name="module_key_pair_worker_asg"></a> [key\_pair\_worker\_asg](#module\_key\_pair\_worker\_asg) | squareops/keypair/aws | n/a |
| <a name="module_ram_metric_scale_in_alarm"></a> [ram\_metric\_scale\_in\_alarm](#module\_ram\_metric\_scale\_in\_alarm) | terraform-aws-modules/cloudwatch/aws//modules/metric-alarm | ~> 3.0 |
| <a name="module_rds_aurora_sg"></a> [rds\_aurora\_sg](#module\_rds\_aurora\_sg) | terraform-aws-modules/security-group/aws | ~> 4.13 |
| <a name="module_rds_records"></a> [rds\_records](#module\_rds\_records) | terraform-aws-modules/route53/aws//modules/records | ~> 2.0 |
| <a name="module_s3_bucket_alb_access_logs"></a> [s3\_bucket\_alb\_access\_logs](#module\_s3\_bucket\_alb\_access\_logs) | terraform-aws-modules/s3-bucket/aws | ~> 3.7.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | squareops/vpc/aws | n/a |
| <a name="module_vpn_records"></a> [vpn\_records](#module\_vpn\_records) | terraform-aws-modules/route53/aws//modules/records | ~> 2.0 |
| <a name="module_worker_asg"></a> [worker\_asg](#module\_worker\_asg) | terraform-aws-modules/autoscaling/aws | 6.7.0 |
| <a name="module_worker_asg_sg"></a> [worker\_asg\_sg](#module\_worker\_asg\_sg) | terraform-aws-modules/security-group/aws | ~> 4.13 |
| <a name="module_worker_sqs"></a> [worker\_sqs](#module\_worker\_sqs) | terraform-aws-modules/sqs/aws | 4.0.1 |

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_policy.app_asg_RAM_scale_in_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy) | resource |
| [aws_autoscaling_policy.app_asg_RAM_scale_out_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy) | resource |
| [aws_codebuild_project.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_codebuild_project.worker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_codedeploy_app.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_app) | resource |
| [aws_codedeploy_app.worker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_app) | resource |
| [aws_codedeploy_deployment_group.app_deploy_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_deployment_group) | resource |
| [aws_codedeploy_deployment_group.worker_deploy_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_deployment_group) | resource |
| [aws_codepipeline.codepipeline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codepipeline) | resource |
| [aws_codepipeline.worker_codepipeline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codepipeline) | resource |
| [aws_codestarconnections_connection.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codestarconnections_connection) | resource |
| [aws_codestarconnections_connection.worker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codestarconnections_connection) | resource |
| [aws_db_parameter_group.aurora_db_mysql](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group) | resource |
| [aws_iam_role.codebuild_app_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.codedeploy_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.codepipeline_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.worker_codebuild_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.worker_codedeploy_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.worker_codepipeline_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.codebuild_app_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.codedeploy_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.codepipeline_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.codepipeline_worker_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.worker_codebuild_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.worker_codedeploy_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_rds_cluster_parameter_group.aurora_db_mysql](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_parameter_group) | resource |
| [aws_s3_bucket.codepipeline-bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.codepipeline-worker-bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.codepipeline-bucket-acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_acl.codepipeline-worker-bucket-acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_master_password"></a> [master\_password](#input\_master\_password) | The password for the DB master user | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_access_logs_s3_bucket_arn"></a> [access\_logs\_s3\_bucket\_arn](#output\_access\_logs\_s3\_bucket\_arn) | The ARN of the bucket. Will be of format arn:aws:s3:::bucketname. |
| <a name="output_acm_certificate_arn"></a> [acm\_certificate\_arn](#output\_acm\_certificate\_arn) | The ARN of the certificate |
| <a name="output_acm_certificate_status"></a> [acm\_certificate\_status](#output\_acm\_certificate\_status) | Status of the certificate. |
| <a name="output_app_autoscaling_group_arn"></a> [app\_autoscaling\_group\_arn](#output\_app\_autoscaling\_group\_arn) | The ARN for App AutoScaling Group |
| <a name="output_app_autoscaling_group_id"></a> [app\_autoscaling\_group\_id](#output\_app\_autoscaling\_group\_id) | The autoscaling group id of app |
| <a name="output_app_autoscaling_group_load_balancers"></a> [app\_autoscaling\_group\_load\_balancers](#output\_app\_autoscaling\_group\_load\_balancers) | The load balancer names associated with the autoscaling group |
| <a name="output_app_autoscaling_group_target_group_arns"></a> [app\_autoscaling\_group\_target\_group\_arns](#output\_app\_autoscaling\_group\_target\_group\_arns) | List of Target Group ARNs that apply to this AutoScaling Group |
| <a name="output_app_autoscaling_policy_arns"></a> [app\_autoscaling\_policy\_arns](#output\_app\_autoscaling\_policy\_arns) | ARNs of app autoscaling policies |
| <a name="output_app_https_listener_arns"></a> [app\_https\_listener\_arns](#output\_app\_https\_listener\_arns) | The ARNs of the HTTPS load balancer listeners created |
| <a name="output_app_iam_role_arn"></a> [app\_iam\_role\_arn](#output\_app\_iam\_role\_arn) | The Amazon Resource Name (ARN) specifying the IAM role |
| <a name="output_app_launch_template_id"></a> [app\_launch\_template\_id](#output\_app\_launch\_template\_id) | The ID of the launch template |
| <a name="output_app_lb_arn"></a> [app\_lb\_arn](#output\_app\_lb\_arn) | The ID and ARN of the load balancer we created |
| <a name="output_app_lb_dns_name"></a> [app\_lb\_dns\_name](#output\_app\_lb\_dns\_name) | The DNS name of the load balancer |
| <a name="output_app_route53_record_name"></a> [app\_route53\_record\_name](#output\_app\_route53\_record\_name) | The name of the record |
| <a name="output_app_sg_security_group_id"></a> [app\_sg\_security\_group\_id](#output\_app\_sg\_security\_group\_id) | The ID of the security group of Application ASG |
| <a name="output_db_security_group_id"></a> [db\_security\_group\_id](#output\_db\_security\_group\_id) | The security group ID of the cluster |
| <a name="output_lb_id"></a> [lb\_id](#output\_lb\_id) | The ID and ARN of the load balancer we created |
| <a name="output_lb_zone_id"></a> [lb\_zone\_id](#output\_lb\_zone\_id) | The zone\_id of the load balancer to assist with creating DNS records |
| <a name="output_public_subnets"></a> [public\_subnets](#output\_public\_subnets) | List of IDs of public subnets |
| <a name="output_rds_cluster_arn"></a> [rds\_cluster\_arn](#output\_rds\_cluster\_arn) | Amazon Resource Name (ARN) of RDS cluster |
| <a name="output_rds_cluster_database_name"></a> [rds\_cluster\_database\_name](#output\_rds\_cluster\_database\_name) | Name for an automatically created database on cluster creation |
| <a name="output_rds_cluster_endpoint"></a> [rds\_cluster\_endpoint](#output\_rds\_cluster\_endpoint) | Writer endpoint for the cluster |
| <a name="output_target_group_arns"></a> [target\_group\_arns](#output\_target\_group\_arns) | ARNs of the target groups. Useful for passing to your Auto Scaling group |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | IPV4 CIDR Block for this VPC |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC |
| <a name="output_vpn_host_public_ip"></a> [vpn\_host\_public\_ip](#output\_vpn\_host\_public\_ip) | IP Address of VPN Server |
| <a name="output_vpn_security_group"></a> [vpn\_security\_group](#output\_vpn\_security\_group) | Security Group ID of VPN Server |
| <a name="output_worker_autoscaling_group_arn"></a> [worker\_autoscaling\_group\_arn](#output\_worker\_autoscaling\_group\_arn) | The ARN for Worker AutoScaling Group |
| <a name="output_worker_autoscaling_group_id"></a> [worker\_autoscaling\_group\_id](#output\_worker\_autoscaling\_group\_id) | The autoscaling group id of worker |
| <a name="output_worker_autoscaling_group_load_balancers"></a> [worker\_autoscaling\_group\_load\_balancers](#output\_worker\_autoscaling\_group\_load\_balancers) | The load balancer names associated with the autoscaling group |
| <a name="output_worker_autoscaling_group_target_group_arns"></a> [worker\_autoscaling\_group\_target\_group\_arns](#output\_worker\_autoscaling\_group\_target\_group\_arns) | List of Target Group ARNs that apply to this AutoScaling Group |
| <a name="output_worker_autoscaling_policy_arns"></a> [worker\_autoscaling\_policy\_arns](#output\_worker\_autoscaling\_policy\_arns) | ARNs of worker autoscaling policies |
| <a name="output_worker_iam_role_arn"></a> [worker\_iam\_role\_arn](#output\_worker\_iam\_role\_arn) | The Amazon Resource Name (ARN) specifying the IAM role |
| <a name="output_worker_launch_template_id"></a> [worker\_launch\_template\_id](#output\_worker\_launch\_template\_id) | The ID of the launch template |
| <a name="output_worker_sg_security_group_id"></a> [worker\_sg\_security\_group\_id](#output\_worker\_sg\_security\_group\_id) | The ID of the security group of Worker Application ASG |
<!-- END_TF_DOCS -->