resource "aws_route53_record" "home" {
  zone_id = local.zone.id
  name    = local.zone.name
  type    = "A"
  count   = terraform.workspace == "prod" ? 0 : 1

  alias {
	name                   = aws_alb.app-servers.dns_name
	zone_id                = aws_alb.app-servers.zone_id
	evaluate_target_health = false
  }
}

resource "aws_route53_record" "api-data" {
  zone_id = local.zone.id
  name    = "api.${local.zone.name}"
  type    = "A"

  alias {
	name                   = aws_alb.app-servers.dns_name
	zone_id                = aws_alb.app-servers.zone_id
	evaluate_target_health = false
  }
}

resource "aws_route53_record" "portal" {
  zone_id = local.zone.id
  name    = "portal.${local.zone.name}"
  type    = "A"

  alias {
	name                   = aws_alb.app-servers.dns_name
	zone_id                = aws_alb.app-servers.zone_id
	evaluate_target_health = false
  }
}

resource "aws_route53_record" "www" {
  zone_id = local.zone.id
  name    = "www.${local.zone.name}"
  type    = "A"
  count   = terraform.workspace == "dev" ? 1 : 0

  alias {
	name                   = aws_alb.app-servers.dns_name
	zone_id                = aws_alb.app-servers.zone_id
	evaluate_target_health = false
  }
}

resource "aws_route53_record" "app-servers" {
  zone_id = local.zone.id
  name    = "app-servers.aws.${local.zone.name}"
  type    = "A"
  ttl     = "60"
  records = [ for key, value in aws_instance.app-servers: value.private_ip ]
  count   = length(aws_instance.app-servers) > 0 ? 1 : 0
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

resource "aws_route53_record" "servers" {
  for_each = aws_instance.app-servers
  zone_id  = aws_route53_zone.private.id
  name     = "${each.key}.${aws_route53_zone.private.name}"
  type     = "A"
  ttl      = "60"
  records  = [ each.value.private_ip ]
}

resource "aws_route53_record" "db" {
  zone_id  = aws_route53_zone.private.id
  name     = "db.${aws_route53_zone.private.name}"
  type     = "CNAME"
  ttl      = "60"
  records  = [ local.database_address ]
}
