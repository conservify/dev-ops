data "aws_ami" "bare" {
  owners           = ["self"]
  name_regex       = "^conservify-bare-.*"
  most_recent      = true
}

data "template_file" "app_server_user_data" {
  template = file("user_data.sh")

  vars = {
	hostname             = "${local.env}-app-server"
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

	database_url         = "${var.database_url}"
  }
}

resource "aws_instance" "app-server" {
  depends_on                  = [aws_internet_gateway.fk]
  ami                         = data.aws_ami.bare.id
  subnet_id                   = aws_subnet.fk-a.id
  instance_type               = "t2.micro"
  vpc_security_group_ids      = ["${aws_security_group.ssh.id}", "${aws_security_group.fk-app-server.id}"]
  user_data                   = data.template_file.app_server_user_data.rendered
  monitoring                  = true
  key_name                    = "cfy-dev-server"
  iam_instance_profile        = aws_iam_instance_profile.fk-server.id
  availability_zone           = var.azs[0]

  lifecycle {
	ignore_changes = [ ami, user_data ]
	create_before_destroy = true
  }

  root_block_device {
	volume_type = "gp2"
	volume_size = 100
  }

  tags = {
	Name = "${local.env}-app-server"
  }
}
