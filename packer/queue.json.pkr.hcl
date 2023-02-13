# This file was autogenerated by the 'packer hcl2_upgrade' command. We
# recommend double checking that everything is correct before going forward. We
# also recommend treating this file as disposable. The HCL2 blocks in this
# file can be moved to other files. For example, the variable blocks could be
# moved to their own 'variables.pkr.hcl' file, etc. Those files need to be
# suffixed with '.pkr.hcl' to be visible to Packer. To use multiple files at
# once they also need to be in the same folder. 'packer inspect folder/'
# will describe to you what is in that folder.

# Avoid mixing go templating calls ( for example ```{{ upper(`string`) }}``` )
# and HCL2 calls (for example '${ var.string_value_example }' ). They won't be
# executed together and the outcome will be unknown.

# All generated input variables will be of 'string' type as this is how Packer JSON
# views them; you can change their type later on. Read the variables type
# constraints documentation
# https://www.packer.io/docs/templates/hcl_templates/variables#type-constraints for more info.
variable "ami_name" {
  type    = string
  default = "Queue-App"
}

variable "instance_size" {
  type    = string
  default = "t3a.micro"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "subnet_id" {
  type    = string
  default = "subnet-0a067da4dd10dd6eb"
}

variable "vpc_id" {
  type    = string
  default = "vpc-00dd3f4de32c1808f"
}

# source blocks are generated from your builders; a source can be referenced in
# build blocks. A build block runs provisioner and post-processors on a
# source. Read the documentation for source blocks here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/source
source "amazon-ebs" "autogenerated_1" {
  access_key           = ""
  ami_name             = "${var.ami_name}"
  iam_instance_profile = "chirag-codedeploy-cloudwatch"
  instance_type        = "t3a.small"
  region               = "us-east-1"
  secret_key           = ""
  source_ami           = "ami-0778521d914d23bc1"
  ssh_pty              = "true"
  ssh_timeout          = "20m"
  ssh_username         = "ubuntu"
  subnet_id            = "${var.subnet_id}"
  vpc_id               = "${var.vpc_id}"
}

# a build block invokes sources and runs provisioning steps on them. The
# documentation for build blocks can be found here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/build
build {
  sources = ["source.amazon-ebs.autogenerated_1"]

  provisioner "shell" {
    pause_before = "10s"
    script       = "queue_dependencies.sh"
    timeout      = "10s"
  }

}
