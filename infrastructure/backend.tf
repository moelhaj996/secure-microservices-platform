# Temporarily using local backend until S3 bucket is created
terraform {
  backend "local" {}
}

# Will uncomment this after S3 bucket is created
# terraform {
#   backend "s3" {
#     bucket         = "secure-microservices-terraform-state"
#     key            = "terraform.tfstate"
#     region         = "us-west-2"
#     encrypt        = true
#     dynamodb_table = "terraform-state-lock"
#   }
# }

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-state-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "terraform-state-lock"
    Environment = var.environment
  }
} 