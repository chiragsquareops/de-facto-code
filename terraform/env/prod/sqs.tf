module "sqs" {
  source = "terraform-aws-modules/sqs/aws"

  name = format("%s_%s_worker_sqs", local.Environment, local.Name)

  fifo_queue = true

  tags = {
    Environment = local.Environment
    Name        = local.Name
  }
}