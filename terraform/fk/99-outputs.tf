output "app_server_address" {
  value = "fk-server-a.aws.${local.zone_name}"
}

output "database_url" {
  value = "${var.database_url}"
}

output "bare_ami_id" {
  value = "${data.aws_ami.bare.id}"
}
