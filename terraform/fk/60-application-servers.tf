data "template_file" "fk-app-server-a" {
  template = "${file("${path.module}/fk-app-server.yml")}"

  vars = {
	hostname             = "fk-app-server-a"
	app_server_container = "${var.app_server_container}"
	zone_name            = "${var.zone_name}"
	database_url         = "${var.database_url}"
	gelf_address         = "${var.gelf_address}"
	gelf_tags            = "${var.gelf_tags}"
  }
}

data "template_file" "fk-app-server-a-compose" {
  template = "${file("${path.module}/fk-compose.yml")}"

  vars = {
	hostname             = "fk-app-server-a"
	app_server_container = "${var.app_server_container}"
	zone_name            = "${var.zone_name}"
	database_url         = "${var.database_url}"
	gelf_address         = "${var.gelf_address}"
	gelf_tags            = "${var.gelf_tags}"
  }
}

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

  /*
  connection {
	user = "core"
	agent = false
	private_key = file("/home/jlewallen/.ssh/cfy.pem")
  }
  */

  root_block_device {
	volume_type = "gp2"
	volume_size = 100
  }

  tags = {
	Name = "fk-app-server-${var.azs[0]}"
  }

  provisioner "remote-exec" {
	inline = [
	  "sudo mkdir -p /opt/bin",
	  "sudo curl -L \"https://github.com/docker/compose/releases/download/1.20.0-rc1/docker-compose-Linux-x86_64\" -o /opt/bin/docker-compose",
	  "sudo chmod +x /opt/bin/docker-compose",
	  "sudo mkdir -p /etc/docker/compose",
	  "sudo chown -R core. /etc/docker",
	]
  }

  provisioner "file" {
	content      = data.template_file.fk-app-server-a-compose.rendered
	destination = "/etc/docker/compose/fk-compose.yml"
  }
}
