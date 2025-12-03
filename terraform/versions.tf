terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Optional: Use S3 backend for state management (recommended for production)
  # Uncomment and configure for team collaboration and state locking
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "mock-fitband-api/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock" # For state locking
  # }
}

