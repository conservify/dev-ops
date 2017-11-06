resource "aws_security_group" "ssh" {
  name        = "ssh"
  description = "ssh"
  vpc_id      = "${aws_vpc.fk.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "${var.whitelisted_cidrs}"
  }

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
  vpc_id      = "${aws_vpc.fk.id}"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = "${var.whitelisted_cidrs}"
    security_groups = ["${aws_security_group.fk-server-alb.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "fk-server-alb" {
  name        = "fk-server-alb"
  description = "fk-server-alb"
  vpc_id      = "${aws_vpc.fk.id}"

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

data "template_file" "fk-app-server-a" {
  template = "${file("${path.module}/fk-app-server.yaml")}"

  vars {
    hostname             = "fk-app-server-a"
    app_server_container = "${var.app_server_container}"
    db_username          = "${var.db_username}"
    db_name              = "${var.db_name}"
    db_password          = "${var.db_password}"
    db_address           = "${module.database.db_address}"
    db_url               = "${module.database.db_url}"
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
  availability_zone           = "${element(var.azs, count.index)}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 100
  }

  tags {
    Name = "fk-app-server-${count.index}"
  }
}

resource "aws_alb" "fk-server" {
  name            = "fk-server"
  internal        = false
  security_groups = ["${aws_security_group.fk-server-alb.id}"]
  subnets         = ["${aws_subnet.fk-a.id}", "${aws_subnet.fk-b.id}", "${aws_subnet.fk-c.id}", "${aws_subnet.fk-e.id}"]

  tags {
    Name = "fk-server"
  }
}

resource "aws_alb_listener" "fk-server-80" {
  load_balancer_arn = "${aws_alb.fk-server.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.fk-server.arn}"
    type             = "forward"
  }
}

resource "aws_alb_listener" "fk-server-443" {
  load_balancer_arn = "${aws_alb.fk-server.arn}"
  port              = "443"
  protocol          = "HTTPS"

  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = "${var.certificate_arn}"

  default_action {
    target_group_arn = "${aws_alb_target_group.fk-server.arn}"
    type             = "forward"
  }
}

resource "aws_alb_target_group" "fk-server" {
  name     = "fk-server"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.fk.id}"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    port                = 80
    path                = "/status"
    interval            = 5
  }
}

resource "aws_alb_target_group_attachment" "fk-server-a" {
  target_group_arn = "${aws_alb_target_group.fk-server.arn}"
  target_id        = "${aws_instance.fk-app-server-a.id}"
  port             = 80
}

module "database" {
  source = "./database"

  db_name                      = "${var.db_name}"
  db_username                  = "${var.db_username}"
  db_password                  = "${var.db_password}"
  app_server_security_group_id = "${aws_security_group.fk-app-server.id}"
  db_subnet_group_name         = "${aws_db_subnet_group.fk.name}"
  vpc_id                       = "${aws_vpc.fk.id}"
}

output "db_password" {
  value     = "${var.db_password}"
  sensitive = true
}

output "db_address" {
  value = "${module.database.db_address}"
}

output "db_url" {
  value = "${module.database.db_url}"
}
