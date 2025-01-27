#Deafult aws provider configuration
provider "aws" {
  region = var.region
}

#Additional aws provider configuration
#This is neccesary for me to be able to use the certificate I already have as it it hosted in a different region
provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
}

provider "archive" {}