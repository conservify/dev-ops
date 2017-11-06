variable "access_key" {}
variable "secret_key" {}

variable "region" {
  default = "us-east-1"
}

variable "zone_id" {}
variable "zone_name" {}

variable "whitelisted_cidrs" {
  default = []
}
