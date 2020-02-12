resource "aws_instance" "fk-app-server-a" {
  depends_on                  = [aws_internet_gateway.fk]
  ami                         = "ami-a89d3ad2"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.fk-a.id
  associate_public_ip_address = true
  vpc_security_group_ids      = ["${aws_security_group.ssh.id}", "${aws_security_group.fk-app-server.id}"]
  #user_data                   = data.ct_config.fk-app-server-a.rendered
  monitoring                  = true
  key_name                    = "cfy-dev-server"
  iam_instance_profile        = aws_iam_instance_profile.fk-server.id
  availability_zone           = var.azs[0]

  lifecycle {
	ignore_changes = [ user_data ]
  }

  root_block_device {
	volume_type = "gp2"
	volume_size = 100
  }

  tags = {
	Name = "fk-app-server-${var.azs[0]}"
  }
}

data "template_file" "fk_app_server_user_data" {
  template = file("user_data.sh")
  vars = {
	hostname             = "fk-app-server-a"
	zone_name            = "${var.zone_name}"
	gelf_url             = "${var.gelf_url}"
	gelf_tags            = "${var.gelf_tags}"
	env_tag              = "${var.env_tag}"

	database_url         = "${var.database_url}"

	influx_url           = "${var.influx_url}"
	influx_database      = "${var.influx_database}"
	influx_user          = "${var.influx_user}"
	influx_password      = "${var.influx_password}"

	aws_access_key       = "${var.access_key}"
	aws_secret_key       = "${var.secret_key}"
  }
}

resource "aws_instance" "fk-app-server-test" {
  depends_on                  = [aws_internet_gateway.fk]
  ami                         = var.application_ami
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.fk-a.id
  associate_public_ip_address = true
  vpc_security_group_ids      = ["${aws_security_group.ssh.id}", "${aws_security_group.fk-app-server.id}"]
  user_data                   = data.template_file.fk_app_server_user_data.rendered
  monitoring                  = true
  key_name                    = "cfy-dev-server"
  iam_instance_profile        = aws_iam_instance_profile.fk-server.id
  availability_zone           = var.azs[0]

  lifecycle {
	ignore_changes = [ user_data ]
  }

  root_block_device {
	volume_type = "gp2"
	volume_size = 100
  }

  tags = {
	Name = "fk-app-server-${var.azs[0]}"
  }
}