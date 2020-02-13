resource "aws_security_group" "ssh" {
  name        = "ssh"
  description = "ssh"
  vpc_id      = aws_vpc.fk.id

  ingress {
	from_port   = 22
	to_port     = 22
	protocol    = "tcp"
	cidr_blocks = var.bastion_manual_cidr
	description = var.bastion_manual_name
  }

  ingress {
	from_port   = 22
	to_port     = 22
	protocol    = "tcp"
	cidr_blocks = var.bastion_tooling_cidr
	description = var.bastion_tooling_name
  }

  /*
  ingress {
	from_port   = 22
	to_port     = 22
	protocol    = "tcp"
	cidr_blocks = var.bastion_manual_cidr
	description = var.bastion_manual_name
  }
  */

  egress {
	from_port   = 0
	to_port     = 0
	protocol    = "-1"
	cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "fk-app-server" {
  name        = "fk-app-server"
  description = "fk-app-server"
  vpc_id      = aws_vpc.fk.id

  ingress {
	from_port       = 8000
	to_port         = 8000
	protocol        = "tcp"
	security_groups = ["${aws_security_group.fk-server-alb.id}"]
  }

  egress {
	from_port       = 0
	to_port         = 0
	protocol        = "-1"
	cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "fk-server-alb" {
  name        = "fk-server-alb"
  description = "fk-server-alb"
  vpc_id      = aws_vpc.fk.id

  ingress {
	from_port   = 80
	to_port     = 80
	protocol    = "tcp"
	cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
	from_port   = 443
	to_port     = 443
	protocol    = "tcp"
	cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
	from_port   = 0
	to_port     = 0
	protocol    = "-1"
	cidr_blocks = ["0.0.0.0/0"]
  }
}
