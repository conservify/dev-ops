resource "aws_security_group" "cfy-dev-server" {
  name        = "cfy-dev-server"
  description = "cfy-dev-server"
  vpc_id      = "${aws_vpc.cfy-dev.id}"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 50000
    to_port         = 50000
    protocol        = "tcp"
    security_groups = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 45900
    to_port         = 45900
    protocol        = "tcp"
    security_groups = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 42115
    to_port         = 42115
    protocol        = "tcp"
    security_groups = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 1701
    to_port         = 1701
    protocol        = "tcp"
    security_groups = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 500
    to_port         = 500
    protocol        = "udp"
    security_groups = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 12201
    to_port         = 12201
    protocol        = "udp"
    security_groups = ["fk-app-server"]
  }

  ingress {
    from_port       = 4500
    to_port         = 4500
    protocol        = "udp"
    security_groups = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "template_file" "cfy-dev-server" {
  template = "${file("${path.module}/cfy-dev-server.yaml")}"

  vars {
    hostname             = "cfy-dev-server"
  }
}

data "ct_config" "cfy-dev-server" {
  pretty_print = false
  platform     = "ec2"
  content      = "${data.template_file.cfy-dev-server.rendered}"
}

resource "aws_instance" "cfy-dev-server" {
  depends_on                  = ["aws_internet_gateway.cfy-dev"]
  ami                         = "ami-a89d3ad2"
  instance_type               = "t2.large"
  subnet_id                   = "${aws_subnet.cfy-dev-a.id}"
  associate_public_ip_address = true
  vpc_security_group_ids      = ["${aws_security_group.cfy-dev-server.id}"]
  user_data                   = "${data.ct_config.cfy-dev-server.rendered}"
  key_name                    = "cfy-dev-server"
  iam_instance_profile        = "${aws_iam_instance_profile.cfy-dev-server.id}"
  availability_zone           = "us-east-1a"

  root_block_device {
    volume_type = "gp2"
    volume_size = 100
  }
}

data "aws_iam_policy_document" "cfy-dev-server" {
  statement {
    actions = [
      "ec2:*",
    ]

    resources = [
      "*",
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:Region"
      values = [ "us-east1" ]
    }
  }
}

resource "aws_iam_role" "cfy-dev-server" {
  name = "cfy-dev-server"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "cfy-dev-server" {
  name = "cfy-dev-server"
  role = "${aws_iam_role.cfy-dev-server.name}"
}

resource "aws_iam_role_policy" "cfy-dev-server" {
  name   = "cfy-dev-server"
  role   = "${aws_iam_role.cfy-dev-server.id}"
  policy = "${data.aws_iam_policy_document.cfy-dev-server.json}"
}
