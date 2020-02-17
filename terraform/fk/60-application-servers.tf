locals {
  app_instance_type = "${lookup(var.workspace_to_server_instance_type_map, terraform.workspace, "")}"
}

data "aws_ami" "bare" {
  owners           = ["self"]
  name_regex       = "^conservify-bare-.*"
  most_recent      = true
}

data "template_file" "app_server_user_data_testing" {
  template               = file("user_data.yaml")

  vars = {
	hostname             = "${local.env}-test"
	zone_name            = "${local.zone_name}"
	env_tag              = "${local.env}"

	aws_access_key       = "${var.access_key}"
	aws_secret_key       = "${var.secret_key}"

	gelf_url             = "${var.gelf_url}"

	influx_url           = "${var.influx_url}"
	influx_database      = "${var.influx_database}"
	influx_user          = "${var.influx_user}"
	influx_password      = "${var.influx_password}"

	application_start    = "${var.application_start}"
	application_stack    = "${var.application_stack}"

	database_url         = "${local.database_url}"
  }
}

data "template_file" "app_server_user_data" {
  for_each               = local.servers
  template               = file("user_data.yaml")

  vars = {
	hostname             = "${each.value.name}"
	zone_name            = "${local.zone_name}"
	env_tag              = "${local.env}"

	aws_access_key       = "${var.access_key}"
	aws_secret_key       = "${var.secret_key}"

	gelf_url             = "${var.gelf_url}"

	influx_url           = "${var.influx_url}"
	influx_database      = "${var.influx_database}"
	influx_user          = "${var.influx_user}"
	influx_password      = "${var.influx_password}"

	application_start    = "${var.application_start}"
	application_stack    = "${var.application_stack}"

	database_url         = "${local.database_url}"
  }
}

resource "aws_instance" "app-servers" {
  for_each                    = local.servers
  depends_on                  = [aws_internet_gateway.fk]
  ami                         = data.aws_ami.bare.id
  subnet_id                   = aws_subnet.private-a.id
  instance_type               = local.app_instance_type
  vpc_security_group_ids      = ["${aws_security_group.ssh.id}", "${aws_security_group.fk-app-server.id}"]
  user_data                   = data.template_file.app_server_user_data[each.key].rendered
  monitoring                  = true
  associate_public_ip_address = false
  key_name                    = "cfy-dev-server"
  iam_instance_profile        = aws_iam_instance_profile.fk-server.id
  availability_zone           = local.azs[0]

  lifecycle {
	ignore_changes = [ ami, subnet_id ]
	create_before_destroy = true
  }

  root_block_device {
	volume_type = "gp2"
	volume_size = 100
  }

  tags = {
	Name = "${each.value.name}"
  }
}

resource "aws_instance" "app-server-testing" {
  depends_on                  = [aws_internet_gateway.fk]
  ami                         = data.aws_ami.bare.id
  subnet_id                   = aws_subnet.private-a.id
  instance_type               = local.app_instance_type
  vpc_security_group_ids      = ["${aws_security_group.ssh.id}", "${aws_security_group.fk-app-server.id}"]
  user_data                   = data.template_file.app_server_user_data_testing.rendered
  monitoring                  = true
  associate_public_ip_address = false
  key_name                    = "cfy-dev-server"
  iam_instance_profile        = aws_iam_instance_profile.fk-server.id
  availability_zone           = local.azs[0]
  count                       = var.enable_test_server ? 1 : 0

  lifecycle {
	ignore_changes = [ ami ]
	create_before_destroy = true
  }

  root_block_device {
	volume_type = "gp2"
	volume_size = 100
  }

  tags = {
	Name = "${local.env}-app-server-testing"
  }
}
