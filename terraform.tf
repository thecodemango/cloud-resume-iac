terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.76.0"
    }

    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.6.0"
    }
  }

  backend "s3" {
    bucket         = "cloud-resume-tf-state-bucket"
    key            = "v1/terraform.tfstate"
    region         = "ca-central-1"
    dynamodb_table = "state-locking"
    encrypt = true
  }
}