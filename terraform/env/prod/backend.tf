# terraform {
#   backend "s3" {
#     bucket         = "laravel-state"
#     key            = "terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "laravel-state-lock-dynamodb-612604283004"
#     # profile        = "prod-laravel"
#   }
# }
