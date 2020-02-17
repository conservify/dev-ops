resource "aws_alb" "app-servers" {
  name            = "${local.env}-lb"
  internal        = false
  security_groups = [ aws_security_group.fk-server-alb.id ]
  subnets         = [ for key, value in local.network.azs: aws_subnet.public[key].id ]

  tags = {
	Name = local.env
  }
}

resource "aws_alb_listener" "app-servers-80" {
  load_balancer_arn  = aws_alb.app-servers.arn
  port               = "80"
  protocol           = "HTTP"

  default_action {
	target_group_arn = aws_alb_target_group.app-servers.arn
	type             = "forward"
  }
}

resource "aws_alb_listener" "app-servers-443" {
  load_balancer_arn  = aws_alb.app-servers.arn
  port               = "443"
  protocol           = "HTTPS"
  ssl_policy         = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn    = var.certificate_arn

  default_action {
	target_group_arn = aws_alb_target_group.app-servers.arn
	type             = "forward"
  }
}

resource "aws_alb_target_group" "app-servers" {
  name     = "${local.env}-server"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = aws_vpc.fk.id

  health_check {
	healthy_threshold   = 2
	unhealthy_threshold = 2
	timeout             = 3
	port                = 9000
	path                = "/"
	interval            = 5
  }

  tags = {
	Name = "${local.env}"
  }
}

resource "aws_alb_target_group_attachment" "app-servers" {
  for_each         = aws_instance.app-servers
  target_group_arn = aws_alb_target_group.app-servers.arn
  target_id        = each.value.id
  port             = 8000
}
