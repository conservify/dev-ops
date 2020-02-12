variable "access_key" {
}

variable "secret_key" {
}

variable "region" {
  default = "us-east-1"
}

variable "zone_id" {
}

variable "zone_name" {
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

variable "azs" {
  type    = list
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "certificate_arn" {}
variable "gelf_tags" {}
variable "gelf_address" {}
variable "database_url" {}

variable "app_server_container" {
  default = ""
}
