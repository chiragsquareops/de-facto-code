variable "enable_codebuild" {
  type    = bool
  default = false
}

variable "enable_codedeploy" {
  type    = bool
  default = false
}

variable "enable_codepipeline" {
  type    = bool
  default = false
}

variable "Name" {
  type    = string
  default = ""
}

variable "name" {
  type    = string
  default = ""
}

variable "group_name" {
  type    = string
  default = ""
}

variable "image" {
  type    = string
  default = ""
}

variable "type" {
  type    = string
  default = ""
}

variable "stream_name" {
  type    = string
  default = ""
}

variable "location" {
  type    = string
  default = ""
}

variable "compute_platform" {
  type    = string
  default = ""
}

variable "pipeline_name" {
  type    = string
  default = ""
}

variable "output_artifacts" {
  type    = string
  default = ""
}

variable "FullRepositoryId" {
  type    = string
  default = ""
}

variable "BranchName" {
  type    = string
  default = ""
}

variable "autoscaling_groups" {
  type    = string
  default = ""
}