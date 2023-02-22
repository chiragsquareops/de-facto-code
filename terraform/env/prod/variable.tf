variable "master_username" {
  description = "The username for the DB master user"
  type        = string
  sensitive   = true
}
variable "master_password" {
  description = "The password for the DB master user"
  type        = string
  sensitive   = true
}