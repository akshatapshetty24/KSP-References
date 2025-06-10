provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "tf_state" {
  bucket = "terraform-state-${random_id.suffix.hex}"
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = {
    Name = "Terraform State Storage"
  }
}

resource "aws_dynamodb_table" "tf_locks" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform State Lock Table"
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

output "s3_bucket_name" {
  value = aws_s3_bucket.tf_state.id
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.tf_locks.name
}
