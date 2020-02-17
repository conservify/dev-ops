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

variable "workspace_to_server_instance_type_map" {
  type = map

  default = {
	dev = "t2.micro"
	stage = "t2.micro"
	prod = "db.r4.large"
  }
}

variable "workspace_to_database_instance_type_map" {
  type = map

  default = {
	dev = "db.t2.micro"
	stage = "db.t2.micro"
	prod = "t3.medium"
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
	dev = "fk-streams" // TODO Fix this, someday.
	stage = "fkstg-streams"
	prod = "fkprod-streams"
  }
}

variable "workspace_to_media_bucket_name" {
  type = map

  default = {
	dev = "fk-media" // TODO Fix this, someday.
	stage = "fkstg-media"
	prod = "fkprod-media"
  }
}

variable "workspace_to_database_id_map" {
  type = map

  default = {
	dev = "fk-staging"
	stage = "fk-staging"
	prod = "fk-prod"
  }
}

variable "workspace_to_database_password_map" {
  type = map
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

variable "database_name" {
  default = "fk"
}

variable "database_username" {
  default = "fk"
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

locals {
  zone_id = "${lookup(var.workspace_to_zone_id_map, terraform.workspace, "")}"
  zone_name = "${lookup(var.workspace_to_zone_name_map, terraform.workspace, "")}"
  env = "${lookup(var.workspace_to_tag_map, terraform.workspace, "")}"
}

variable "enable_test_server" {
  default = false
}

variable "servers" {
  default = {
	dev: {
		deploying = {
		name = "red"
		number = 0
		}
		running = {
		name = "blue"
		number = 1
		}
	}
  }
}

variable "network" {
  default = {
	dev: {
	  cidr: "10.1.0.0/16"
	  peering: "pcx-004194d2bf8d19d28"
	  azs: {
		"us-east-1a" = {
		  public: "10.1.1.0/24"
		  private: "10.1.5.0/24"
		  exposed: true
		}
		"us-east-1e" = {
		  public: "10.1.4.0/24"
		  private: "10.1.8.0/24"
		  exposed: false
		}
	  }
	}
  }
}

locals {
  workspace_servers = lookup(var.servers, terraform.workspace, null)
  network = lookup(var.network, terraform.workspace, null)
  azs = local.network.azs

  zones = keys(local.azs)

  all = flatten([
	for k, v in local.workspace_servers : [
	  for r in range(v.number) : {
		name = "${local.env}-${v.name}-${r}"
		number = r
		config = v
		zone = local.zones[r % length(local.zones)]
	  }
	]
  ])
  servers = {
	for r in local.all : r.name => r
  }
}
