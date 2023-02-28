

output "public_subnets" {
  value       = module.vpc.public_subnets
  description = "List of IDs of public subnets"
}

output "vpc_cidr_block" {
  value       = module.vpc.vpc_cidr_block
  description = "IPV4 CIDR Block for this VPC"
}

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The ID of the VPC"
}

output "vpn_host_public_ip" {
  value       = module.vpc.vpn_host_public_ip
  description = "IP Address of VPN Server"
}

output "vpn_security_group" {
  value       = module.vpc.vpn_security_group
  description = "Security Group ID of VPN Server"
}

output "rds_cluster_arn" {
  value       = module.aurora_mysql.cluster_arn
  description = "Amazon Resource Name (ARN) of RDS cluster"
}

output "rds_cluster_database_name" {
  value       = module.aurora_mysql.cluster_database_name
  description = "Name for an automatically created database on cluster creation"
}

output "rds_cluster_endpoint" {
  value       = module.aurora_mysql.cluster_endpoint
  description = "Writer endpoint for the cluster"
}

output "db_security_group_id" {
  value       = module.aurora_mysql.security_group_id
  description = "The security group ID of the cluster"
}

output "access_logs_s3_bucket_arn" {
  value       = module.s3_bucket_alb_access_logs.s3_bucket_arn
  description = "The ARN of the bucket. Will be of format arn:aws:s3:::bucketname."
}

output "app_sg_security_group_id" {
  value       = module.app_asg_sg.security_group_id
  description = "The ID of the security group of Application ASG"
}

output "app_autoscaling_group_arn" {
  value       = module.app_asg.autoscaling_group_arn
  description = "The ARN for App AutoScaling Group"
}

output "app_autoscaling_group_id" {
  value       = module.app_asg.autoscaling_group_id
  description = "The autoscaling group id of app"
}

output "app_autoscaling_group_load_balancers" {
  value       = module.app_asg.autoscaling_group_load_balancers
  description = "The load balancer names associated with the autoscaling group"
}

output "app_autoscaling_group_target_group_arns" {
  value       = module.app_asg.autoscaling_group_target_group_arns
  description = "List of Target Group ARNs that apply to this AutoScaling Group"
}

output "app_autoscaling_policy_arns" {
  value       = module.app_asg.autoscaling_policy_arns
  description = "ARNs of app autoscaling policies"
}

output "app_iam_role_arn" {
  value       = module.app_asg.iam_role_arn
  description = "The Amazon Resource Name (ARN) specifying the IAM role"
}

output "app_launch_template_id" {
  value       = module.app_asg.launch_template_id
  description = "The ID of the launch template"
}

output "worker_sg_security_group_id" {
  value       = module.worker_asg_sg.security_group_id
  description = "The ID of the security group of Worker Application ASG"
}

output "worker_autoscaling_group_arn" {
  value       = module.worker_asg.autoscaling_group_arn
  description = "The ARN for Worker AutoScaling Group"
}

output "worker_autoscaling_group_id" {
  value       = module.worker_asg.autoscaling_group_id
  description = "The autoscaling group id of worker"
}

output "worker_autoscaling_group_load_balancers" {
  value       = module.worker_asg.autoscaling_group_load_balancers
  description = "The load balancer names associated with the autoscaling group"
}

output "worker_autoscaling_group_target_group_arns" {
  value       = module.worker_asg.autoscaling_group_target_group_arns
  description = "List of Target Group ARNs that apply to this AutoScaling Group"
}

output "worker_autoscaling_policy_arns" {
  value       = module.worker_asg.autoscaling_policy_arns
  description = "ARNs of worker autoscaling policies"
}

output "worker_iam_role_arn" {
  value       = module.worker_asg.iam_role_arn
  description = "The Amazon Resource Name (ARN) specifying the IAM role"
}

output "worker_launch_template_id" {
  value       = module.worker_asg.launch_template_id
  description = "The ID of the launch template"
}

output "app_https_listener_arns" {
  value       = module.alb.https_listener_arns
  description = "The ARNs of the HTTPS load balancer listeners created"
}

output "app_lb_arn" {
  value       = module.alb.lb_arn
  description = "The ID and ARN of the load balancer we created"
}

output "app_lb_dns_name" {
  value       = module.alb.lb_dns_name
  description = "The DNS name of the load balancer"
}

output "lb_id" {
  value       = module.alb.lb_id
  description = "The ID and ARN of the load balancer we created"
}

output "lb_zone_id" {
  value       = module.alb.lb_zone_id
  description = "The zone_id of the load balancer to assist with creating DNS records"
}

output "target_group_arns" {
  value       = module.alb.target_group_arns
  description = "ARNs of the target groups. Useful for passing to your Auto Scaling group"
}

output "acm_certificate_arn" {
  value       = module.acm.acm_certificate_arn
  description = "The ARN of the certificate"
}

output "acm_certificate_status" {
  value       = module.acm.acm_certificate_status
  description = "Status of the certificate."
}

output "app_route53_record_name" {
  value       = module.app_instance_records.route53_record_name
  description = "The name of the record"
}
