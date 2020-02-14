variable workspace_to_tag_map {
  type = map

  default = {
	dev = "fkdev"
	stage = "fkstg"
	prod = "fkprod"
  }
}

variable "workspace_to_zone_name_map" {
  type = map

  default = {
	dev = "fkdev.org"
	stage = "fkstg.org"
	prod = "fieldkit.org"
  }
}

variable "workspace_to_zone_id_map" {
  type = map

  default = {
	dev = "Z18S4MHBIRCCI4"
	stage = "ZWSMQWHE9K5XZ"
	prod = "Z323K3Z1TB3R58"
  }
}

variable "workspace_to_streams_bucket_name" {
  type = map

  default = {
	dev = "fk-streams"
	stage = "fkstg-streams"
	prod = "fkprod-streams"
  }
}

variable "workspace_to_media_bucket_name" {
  type = map

  default = {
	dev = "fk-media"
	stage = "fkstg-media"
	prod = "fkprod-media"
  }
}

variable "workspace_to_network_map" {
  type = map

  default = {
	dev = "10.0.0.0/16"
	stage = "10.1.0.0/16"
	prod = "10.10.0.0/16"
  }
}

variable "workspace_to_network_a_map" {
  type = map

  default = {
	dev = "10.0.0.0/18"
	stage = ""
	prod = ""
  }
}

variable "workspace_to_network_b_map" {
  type = map

  default = {
	dev = "10.0.64.0/18"
	stage = ""
	prod = ""
  }
}

variable "workspace_to_network_c_map" {
  type = map

  default = {
	dev = "10.0.128.0/18"
	stage = ""
	prod = ""
  }
}

variable "workspace_to_network_e_map" {
  type = map

  default = {
	dev = "10.0.192.0/18"
	stage = ""
	prod = ""
  }
}


variable "access_key" {
}

variable "secret_key" {
}

variable "bastion_manual_cidr" {
  type = list
}

variable "bastion_manual_name" {
}

variable "bastion_tooling_cidr" {
  type = list
}

variable "bastion_tooling_name" {
}

variable "region" {
  default = "us-east-1"
}

variable "azs" {
  type    = list
  default = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1e"]
}

variable "gelf_url" {}

variable "influx_url" {}
variable "influx_database" {}
variable "influx_user" {}
variable "influx_password" {}

variable "application_start" {
  default = ""
}
variable "application_stack" {
  default = ""
}

variable "certificate_arn" {}
variable "database_url" {}

locals {
  zone_id = "${lookup(var.workspace_to_zone_id_map, terraform.workspace, "")}"
  zone_name = "${lookup(var.workspace_to_zone_name_map, terraform.workspace, "")}"
  env = "${lookup(var.workspace_to_tag_map, terraform.workspace, "")}"
}
