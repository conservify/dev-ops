resource "aws_route53_record" "fk-server-a" {
  zone_id = local.zone_id
  name    = "fk-server-a.aws.${local.zone_name}"
  type    = "A"
  ttl     = "60"
  records = ["${aws_instance.app-server.public_ip}"]
}

resource "aws_route53_record" "home" {
  zone_id = local.zone_id
  name    = local.zone_name
  type    = "A"

  alias {
	name                   = aws_alb.fk-server.dns_name
	zone_id                = aws_alb.fk-server.zone_id
	evaluate_target_health = false
  }
}

resource "aws_route53_record" "api-data" {
  zone_id = local.zone_id
  name    = "api.${local.zone_name}"
  type    = "A"

  alias {
	name                   = aws_alb.fk-server.dns_name
	zone_id                = aws_alb.fk-server.zone_id
	evaluate_target_health = false
  }
}

resource "aws_route53_record" "portal" {
  zone_id = local.zone_id
  name    = "portal.${local.zone_name}"
  type    = "A"

  alias {
	name                   = aws_alb.fk-server.dns_name
	zone_id                = aws_alb.fk-server.zone_id
	evaluate_target_health = false
  }
}

resource "aws_route53_record" "www" {
  zone_id = local.zone_id
  name    = "www.${local.zone_name}"
  type    = "A"
  count   = terraform.workspace == "dev" ? 1 : 0

  alias {
	name                   = aws_alb.fk-server.dns_name
	zone_id                = aws_alb.fk-server.zone_id
	evaluate_target_health = false
  }
}

resource "aws_route53_zone" "private" {
  name = "fk.private"

  vpc {
    vpc_id = aws_vpc.fk.id
  }
}

resource "aws_route53_record" "private-logs" {
  zone_id = aws_route53_zone.private.id
  name    = "logs.${aws_route53_zone.private.name}"
  type    = "A"
  ttl     = "300"
  records = [ "172.31.58.48" ]
}

resource "aws_route53_record" "private-metrics" {
  zone_id = aws_route53_zone.private.id
  name    = "metrics.${aws_route53_zone.private.name}"
  type    = "A"
  ttl     = "300"
  records = [ "172.31.58.48" ]
}
