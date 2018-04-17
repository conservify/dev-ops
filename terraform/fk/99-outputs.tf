output "db_password" {
  value     = "${var.db_password}"
  sensitive = true
}

output "db_address" {
  value = "${module.database.db_address}"
}

output "db_url" {
  value = "${module.database.db_url}"
}

output "app_server_container" {
  value = "${var.app_server_container}"
}

output "vpc_id" {
  value = "${aws_vpc.fk.id}"
}

output "db_subnet_group_name" {
  value = "${aws_db_subnet_group.fk.name}"
}

output "internet_gateway_id" {
  value = "${aws_internet_gateway.fk.id}"
}

output "subnet_ids" {
  value = ["${aws_subnet.fk-a.id}", "${aws_subnet.fk-b.id}", "${aws_subnet.fk-c.id}", "${aws_subnet.fk-e.id}"]
}

output "app_server_address" {
  value = "fk-server-a.aws.${var.zone_name}"
}
