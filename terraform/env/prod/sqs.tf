module "worker_sqs" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "4.0.1"

  name = format("%s_%s_worker_sqs", local.Environment, local.Name)

  fifo_queue = false

  tags = {
    Environment = local.Environment
    Name        = local.Name
  }
}
