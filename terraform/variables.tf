variable "bucket" {
  default     = "iac-bucket-test-v1"
  description = "name for the S3 bucket used to store the frontend files"
}

variable "project" {
  default     = "cloud_resume"
  description = "name of the project. Mainly to use in tags"
}

variable "region" {
  default     = "ca-central-1"
  description = "default region for the project"
}