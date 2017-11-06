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
