data "aws_ami" "bare" {
  owners           = ["self"]
  name_regex       = "^conservify-bare-.*"
  most_recent      = true
}

data "template_file" "app_server_user_data" {
  for_each               = local.servers
  template               = file("user_data.yaml")

  vars = {
	hostname             = "${each.value.name}"
	zone_name            = "${local.zone.name}"
	env_tag              = "${local.env}"

	aws_access_key       = "${var.access_key}"
	aws_secret_key       = "${var.secret_key}"

	gelf_url             = "${var.gelf_url}"
	statsd_address       = "${var.statsd_address}"


	influx_url           = "${var.influx_database.url}"
	influx_database      = "${var.influx_database.name}"
	influx_user          = "${var.influx_database.user}"
	influx_password      = "${var.influx_database.password}"

	application_start    = "${each.value.config.start}"
	application_stack    = "${each.value.config.stack}"

	database_url         = "${local.database_url}"
  }
}

resource "aws_instance" "app-servers" {
  for_each                    = local.servers
  depends_on                  = [aws_internet_gateway.fk]
  ami                         = data.aws_ami.bare.id
  subnet_id                   = aws_subnet.private[each.value.zone].id
  instance_type               = each.value.config.instance
  vpc_security_group_ids      = ["${aws_security_group.ssh.id}", "${aws_security_group.fk-app-server.id}"]
  user_data                   = data.template_file.app_server_user_data[each.key].rendered
  monitoring                  = true
  associate_public_ip_address = false
  key_name                    = "cfy-dev-server"
  iam_instance_profile        = aws_iam_instance_profile.fk-server.id
  availability_zone           = each.value.zone

  lifecycle {
	ignore_changes = [ ami ]
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
