variable "min_size" {
  description = ""
  type        = number
  default     = 0
}

variable "max_size" {
  description = ""
  type        = number
  default     = 0
}

variable "desired_capacity" {
  description = ""
  type        = number
  default     = 0
}

variable "vpc_zone_identifier" {
  description = "A list of subnet IDs to launch resources in. Subnets automatically determine which availability zones the group will reside. Conflicts with `availability_zones`"
  type        = list(string)
  default     = []
}

variable "wait_for_capacity_timeout" {
  description = ""
  type        = number
  default     = 0
}

variable "health_check_type" {
  description = ""
  type        = string
  default     = "ELB"
}

variable "enabled_metrics" {
  description = "A list of metrics to collect. The allowed values are `GroupDesiredCapacity`, `GroupInServiceCapacity`, `GroupPendingCapacity`, `GroupMinSize`, `GroupMaxSize`, `GroupInServiceInstances`, `GroupPendingInstances`, `GroupStandbyInstances`, `GroupStandbyCapacity`, `GroupTerminatingCapacity`, `GroupTerminatingInstances`, `GroupTotalCapacity`, `GroupTotalInstances`"
  type        = list(string)
  default     = []
}

variable "instance_refresh" {
  description = "If this block is configured, start an Instance Refresh when this Auto Scaling Group is updated"
  type        = any
  default     = {}
}

variable "image_id" {
  description = "The AMI from which to launch the instance"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "The type of the instance. If present then `instance_requirements` cannot be present"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "The key name that should be used for the instance"
  type        = string
  default     = ""
}

variable "user_data" {
  description = "The Base64-encoded user data to provide when launching the instance"
  type        = string
  default     = ""
}

variable "security_groups" {
  description = "A list of security group IDs to associate"
  type        = list(string)
  default     = []
}

variable "public_subnets" {
  description = "A list of security group IDs to associate"
  type        = list(string)
  default     = []
}

variable "enable_monitoring" {
  description = "Enables/disables detailed monitoring"
  type        = bool
  default     = false
}

variable "ebs_optimized" {
  description = "If true, the launched EC2 instance will be EBS-optimized"
  type        = bool
  default     = false
}

variable "target_group_arns" {
  description = "A set of `aws_alb_target_group` ARNs, for use with Application or Network Load Balancing"
  type        = list(string)
  default     = []
}

variable "iam_instance_profile_arn" {
  description = "Amazon Resource Name (ARN) of an existing IAM instance profile. Used when `create_iam_instance_profile` = `false`"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}

variable "asg_cpu_utilization_policy" {
  description = "Enable or Disable CPU based utilization policy"
  type        = bool
  default     = false
}

variable "name" {
  description = "Name of the Application"
  type        = string
}

variable "cpu_value_threshold" {
  description = "Target value of CPU based utlization Policy"
  type        = number
  default     = 70
}

variable "asg_ALB_request_count_policy" {
  description = ""
  type        = bool
  default     = false
}

variable "request_count_value_threshold" {
  description = ""
  type        = number
  default     = 20
}

variable "asg_RAM_based_scale_out_policy" {
  description = "Enable or Disable RAM based utilization Policy"
  type        = bool
  default     = false
}

variable "threshold_to_scale_out" {
  description = "Target value for RAM based utilization Policy"
  type        = number
  default     = 20
}

variable "asg_RAM_based_scale_in_policy" {
  description = "Enable or Disable RAM based utilization Policy"
  type        = bool
  default     = false
}

variable "threshold_to_scale_in" {
  description = "Target value for RAM based utilization Policy"
  type        = number
  default     = 50
}

variable "asg_queue_scale_in_policy" {
  description = "Enable or Disable Approximate Number of Messages Visible Policy to scale down"
  type        = bool
  default     = false
}

variable "queue_threshold_scale_in" {
  description = "Target value for RAM based utilization Policy"
  type        = number
  default     = 50
}

variable "asg_queue_scale_out_policy" {
  description = "Enable or Disable Approximate Number of Messages Visible Policy to scale down"
  type        = bool
  default     = false
}

variable "queue_threshold_scale_out" {
  description = "Target value for RAM based utilization Policy"
  type        = number
  default     = 50
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = ""
}

variable "Environment" {
  description = "Environment name of the project"
  type        = string
  default     = ""
}

variable "Owner" {
  description = "Name of the Owner"
  type        = string
  default     = ""
}

variable "Terraform" {
  description = "Created by terraform"
  type        = bool
  default     = true
}

variable "backend_protocol" {
  type    = string
  default = ""
}

variable "backend_port" {
  type    = number
  default = 0
}

variable "target_type" {
  type    = string
  default = ""
}

variable "alb_enable" {
  type    = bool
  default = true
}

variable "certificate_arn" {
  type    = string
  default = ""
}