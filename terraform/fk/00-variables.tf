variable "access_key" {}
variable "secret_key" {}

variable "region" {
  default = "us-east-1"
}

variable "zone_id" {}
variable "zone_name" {}

variable "whitelisted_cidrs" {
  type    = "list"
  default = []
}

variable "azs" {
  type    = "list"
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "app_server_container" {
  default = "conservify/fk-cloud:master"
}

variable "db_name" {
  default = "fk"
}

variable "db_username" {
  default = "fk"
}

variable "db_password" {}

variable "certificate_arn" {}

variable "gelf_tags" {
  default = "fkdev"
}

variable "gelf_address" {
  default = "udp://172.31.58.48:12201"
}
