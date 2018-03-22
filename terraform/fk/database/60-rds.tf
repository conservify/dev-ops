resource "aws_security_group" "postgresql" {
  name        = "postgresql"
  description = "postgresql"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = ["${var.app_server_security_group_id}"]
  }
}

resource "aws_db_instance" "staging" {
  identifier = "fk-staging"

  tags {
    Name = "fk-staging"
  }

  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "9.6.6"
  instance_class         = "db.t2.micro"
  name                   = "${var.db_name}"
  username               = "${var.db_username}"
  password               = "${var.db_password}"
  publicly_accessible    = true
  db_subnet_group_name   = "${var.db_subnet_group_name}"
  vpc_security_group_ids = ["${aws_security_group.postgresql.id}"]
}

output "db_address" {
  value = "${aws_db_instance.staging.address}"
}

output "db_url" {
  value = "postgres://${var.db_username}:${var.db_password}@${aws_db_instance.staging.address}/${var.db_name}?sslmode=disable"
}
