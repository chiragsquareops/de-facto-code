# output "region" {
#   description = "AWS Region"
#   value       = local.region
# }

# output "vpc_id" {
#   description = "The ID of the VPC"
#   value       = module.vpc.vpc_id
# }

# output "vpc_cidr_block" {
#   description = "AWS Region"
#   value       = module.vpc.vpc_cidr_block
# }

# output "public_subnets" {
#   description = "List of IDs of public subnets"
#   value       = module.vpc.public_subnets
# }

# output "private_subnets" {
#   description = "List of IDs of private subnets"
#   value       = module.vpc.private_subnets
# }

# output "autoscaling_group_id" {
#   description = "The autoscaling group ID"
#   value       = module.asg.autoscaling_group_id
# }

# output "autoscaling_group_name" {
#   description = "The autoscaling group name"
#   value       = module.asg.autoscaling_group_name
# }

# output "autoscaling_group_min_size" {
#   description = "The minimum size of the autoscale group"
#   value       = module.asg.autoscaling_group_min_size
# }

# output "autoscaling_group_max_size" {
#   description = "The maximum size of the autoscale group"
#   value       = module.asg.autoscaling_group_max_size
# }

# output "autoscaling_group_desired_capacity" {
#   description = "The desired capacity of the autoscale group"
#   value       = module.asg.autoscaling_group_desired_capacity
# }

# output "autoscaling_group_health_check_type" {
#   description = "EC2 or ELB. Controls how health checking is done"
#   value       = module.asg.autoscaling_group_health_check_type
# }

# output "autoscaling_group_load_balancers" {
#   description = "The load balancer names associated with the autoscaling group"
#   value       = module.asg.autoscaling_group_load_balancers
# }


# output "lb_id" {
#   description = "The ID of the load balancer"
#   value       = module.alb.lb_id
# }

# output "lb_arn" {
#   description = "The ARN of the load balancer"
#   value       = module.alb.lb_arn
# }

# output "lb_dns_name" {
#   description = "The DNS name of the load balancer."
#   value       = module.alb.lb_dns_name
# }

# output "lb_zone_id" {
#   description = "The zone_id of the load balancer to assist with creating DNS records."
#   value       = module.alb.lb_zone_id
# }

# output "target_group_names" {
#   description = "Name of the target group"
#   value       = module.alb.target_group_names
# }

# output "target_group_attachments" {
#   description = "ARNs of the target group attachment IDs"
#   value       = module.alb.target_group_attachments
# }

# output "https_listener_ids" {
#   description = "The IDs of the load balancer listeners created"
#   value       = module.alb.https_listener_ids
# }

# output "target_group_arns" {
#   description = "ARNs of the target groups"
#   value       = module.alb.target_group_arns[0]
# }

# output "security_group_id" {
#   description = "The ID of the ALB security group"
#   value       = module.alb-sg.security_group_id
# }