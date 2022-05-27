provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}

terraform {
  backend "s3" {
    bucket = "conservify-terraform-state"
    region = "us-west-2"
    encrypt = true
    key = "fk"
  }
}
