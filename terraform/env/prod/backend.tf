module "backend" {
  source = "squareops/tfstate/aws"
  environment        = local.Environment
  bucket_name        = "prod-laravel-tfstate"
  force_destroy      = true
  versioning_enabled = true
  logging            = true
}