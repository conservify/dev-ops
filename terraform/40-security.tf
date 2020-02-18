resource "aws_security_group" "ssh" {
  name        = "${local.env}-ssh"
  description = "${local.env}-ssh"
  vpc_id      = aws_vpc.fk.id

  ingress {
	from_port   = 22
	to_port     = 22
	protocol    = "tcp"
	cidr_blocks = var.bastions.manual.cidr
	description = var.bastions.manual.name
  }

  ingress {
	from_port   = 22
	to_port     = 22
	protocol    = "tcp"
	cidr_blocks = var.bastions.tooling.cidr
	description = var.bastions.tooling.name
  }

  egress {
	from_port   = 0
	to_port     = 0
	protocol    = "-1"
	cidr_blocks = [ "0.0.0.0/0" ]
  }

  tags = {
	Name = local.env
  }
}

resource "aws_security_group" "db-server" {
  name        = "${local.env}-db-server"
  description = "${local.env}-db-server"
  vpc_id      = aws_vpc.fk.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [ aws_security_group.fk-app-server.id ]
  }

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [ var.infrastructure.sg_id ]
  }

  tags = {
	Name = local.env
  }
}

resource "aws_security_group" "fk-app-server" {
  name        = "${local.env}-app-server"
  description = "${local.env}-app-server"
  vpc_id      = aws_vpc.fk.id

  ingress {
	from_port       = 7000
	to_port         = 7000
	protocol        = "tcp"
	security_groups = [ aws_security_group.fk-server-alb.id ]
  }

  ingress {
	from_port       = 8000
	to_port         = 8000
	protocol        = "tcp"
	security_groups = [ aws_security_group.fk-server-alb.id ]
  }

  ingress {
	from_port       = 9000
	to_port         = 9000
	protocol        = "tcp"
	security_groups = [ aws_security_group.fk-server-alb.id ]
  }

  egress {
	from_port       = 0
	to_port         = 0
	protocol        = "-1"
	cidr_blocks     = [ "0.0.0.0/0" ]
  }

  tags = {
	Name = local.env
  }
}

resource "aws_security_group" "fk-server-alb" {
  name        = "${local.env}-server-alb"
  description = "${local.env}-server-alb"
  vpc_id      = aws_vpc.fk.id

  ingress {
	from_port   = 80
	to_port     = 80
	protocol    = "tcp"
	cidr_blocks = [ "0.0.0.0/0" ]
  }

  ingress {
	from_port   = 443
	to_port     = 443
	protocol    = "tcp"
	cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
	from_port   = 0
	to_port     = 0
	protocol    = "-1"
	cidr_blocks = [ "0.0.0.0/0" ]
  }

  tags = {
	Name = local.env
  }
}
