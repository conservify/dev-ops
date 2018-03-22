provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

data "aws_caller_identity" "current" {}

terraform {
  backend "local" {
    path = "../../../../dropbox/conservify/terraform/fk-cron.tfstate"
  }
}

/*
data "terraform_remote_state" "default" {
  backend = "local"

  config {
    path = "../../../../dropbox/conservify/terraform/fk-cron.tfstate"
  }
}
*/

