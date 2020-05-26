variable region {
  type = string
  default = "us-east-1"
}

variable access_key {
  type = string
}

variable secret_key {
  type = string
}

variable domains {
  default = {
	"fkdev.org": {
	  path: "./letsencrypt/live/fkdev.org"
	},
	"fieldkit.org": {
	  path: "./letsencrypt/live/fieldkit.org"
	}
  }
}

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
	key = "ssl"
  }
}

resource "aws_route53_zone" "domains" {
  name     = each.key
  for_each = var.domains
}

resource "aws_iam_server_certificate" "certificates" {
  for_each          = var.domains
  name_prefix       = each.key
  certificate_body  = file(pathexpand(join("", [each.value.path, "/cert.pem"])))
  private_key       = file(pathexpand(join("", [each.value.path, "/privkey.pem"])))
  certificate_chain = file(pathexpand(join("", [each.value.path, "/chain.pem"])))

  # Some properties of an IAM Server Certificates cannot be updated while they
  # are in use. In order for Terraform to effectively manage a Certificate in
  # this situation, it is recommended you utilize the name_prefix attribute and
  # enable the create_before_destroy lifecycle block.
  lifecycle {
	create_before_destroy = true
	# prevent_destroy = true
  }
}

/*
data "terraform_remote_state" "fk" {
  backend = "s3"
  workspace = "dev"
  config = {
	bucket = "conservify-terraform-state"
	region = "us-west-2"
	encrypt = true
	key = "fk"
  }
}
*/

output certificates {
  value = {
	for key, i in aws_iam_server_certificate.certificates:
	  key => {
		id = i.id,
		arn = i.arn
	  }
  }
}
