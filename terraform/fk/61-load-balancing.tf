resource "aws_alb" "fk-server" {
  name            = "fk-server"
  internal        = false
  security_groups = ["${aws_security_group.fk-server-alb.id}"]
  subnets         = ["${aws_subnet.fk-a.id}", "${aws_subnet.fk-b.id}", "${aws_subnet.fk-c.id}", "${aws_subnet.fk-e.id}"]

  tags = {
	Name = "fk-server"
  }
}

resource "aws_alb_listener" "fk-server-80" {
  load_balancer_arn = aws_alb.fk-server.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
	target_group_arn = aws_alb_target_group.fk-server.arn
	type             = "forward"
  }
}

resource "aws_alb_listener" "fk-server-443" {
  load_balancer_arn = aws_alb.fk-server.arn
  port              = "443"
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = var.certificate_arn

  default_action {
	target_group_arn = aws_alb_target_group.fk-server.arn
	type             = "forward"
  }
}

resource "aws_alb_target_group" "fk-server" {
  name     = "fk-server"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = aws_vpc.fk.id

  health_check {
	healthy_threshold   = 2
	unhealthy_threshold = 2
	timeout             = 3
	port                = 8000
	path                = "/status"
	interval            = 5
  }
}

resource "aws_alb_target_group_attachment" "fk-server-a" {
  target_group_arn = aws_alb_target_group.fk-server.arn
  target_id        = aws_instance.fk-app-server-a.id
  port             = 8000
}
