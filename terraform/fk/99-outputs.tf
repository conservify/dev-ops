output "app_server_address" {
  value = "fk-server-a.aws.${var.zone_name}"
}

output "database_url" {
  value = "${var.database_url}"
}