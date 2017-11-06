resource "aws_security_group" "ssh" {
  name = "ssh"
  description = "ssh"
  vpc_id = "${aws_vpc.fk.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["172.91.15.40/32"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "fk-app-server" {
  name        = "fk-app-server"
  description = "fk-app-server"
  vpc_id      = "${aws_vpc.fk.id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["172.91.15.40/32"]
    // security_groups = ["${aws_security_group.fieldkit-server-alb.id}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "template_file" "fk-app-server-a" {
  template = "${file("${path.module}/fk-app-server.yaml")}"

  vars {
    hostname = "fk-app-server-a"
  }
}

data "ct_config" "fk-app-server-a" {
  pretty_print = false
  content      = "${data.template_file.fk-app-server-a.rendered}"
}

resource "aws_instance" "fk-app-server-a" {
  depends_on                  = ["aws_internet_gateway.fk"]
  ami                         = "ami-a89d3ad2"
  instance_type               = "t2.micro"
  subnet_id                   = "${aws_subnet.fk-a.id}"
  associate_public_ip_address = true
  vpc_security_group_ids      = ["${aws_security_group.ssh.id}", "${aws_security_group.fk-app-server.id}"]
  user_data                   = "${data.ct_config.fk-app-server-a.rendered}"
  key_name                    = "cfy-dev-server"
  iam_instance_profile        = "${aws_iam_instance_profile.fk-server.id}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 100
  }

  tags {
    Name = "fk-app-server-a"
  }
}
