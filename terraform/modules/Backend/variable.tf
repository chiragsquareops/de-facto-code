variable "environment" {
  description = "Select enviroment type: staging,prod"
  default     = "prod"
  type        = string
}

variable "name" {
  description = "name for project"
  default     = ""
  type        = string
}

variable "bucket_name" {
  description = "bucket name"
  default     = "terraform-state"
  type        = string
}

variable "force_destroy" {
  description = "Indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error"
  default     = false
  type        = bool
}

variable "region" {
  description = "In which region S3 bucket will create"
  default     = "us-east-1"
  type        = string
}

variable "versioning_enabled" {
  description = "keeping multiple variants of an object in the same bucket"
  default     = false
  type        = bool
}
