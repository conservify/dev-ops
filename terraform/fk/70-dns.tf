locals {
  running_servers = { for row in
      flatten([
        [ for k, i in aws_instance.app-servers: { name: k, private_ip: i.private_ip } ],
        [ for k, i in aws_instance.pg_servers: { name: k, private_ip: i.private_ip } ]
      ]): row.name => row.private_ip
    }
}


// *.org public facing

resource "aws_route53_record" "home" {
  zone_id = local.zone.id
  name    = local.zone.name
  type    = "A"
  count   = local.production ? 0 : 1

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

# TODO drive this from variables.
resource "aws_route53_record" "floodnet-partner-domain" {
  zone_id = local.partners.floodnet.zone.id
  name    = "dataviz.floodnet.nyc"
  type    = "A"
  count   = local.production ? 1 : 0

  alias {
    name                   = aws_alb.app-servers.dns_name
    zone_id                = aws_alb.app-servers.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "floodnet" {
  zone_id = local.zone.id
  name    = "floodnet.${local.zone.name}"
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
  count   = local.production ? 0 : 1

  alias {
    name                   = aws_alb.app-servers.dns_name
    zone_id                = aws_alb.app-servers.zone_id
    evaluate_target_health = false
  }
}

// *.org internal

resource "aws_route53_record" "app-servers" {
  zone_id = local.zone.id
  name    = "app-servers.aws.${local.zone.name}"
  type    = "A"
  ttl     = "60"
  records = [ for key, value in aws_instance.app-servers: value.private_ip
              if lookup(local.app_servers, key, { config: { live: false } }).config.live ]
  count   = length(aws_instance.app-servers) > 0 ? 1 : 0
}

resource "aws_route53_record" "servers" {
  for_each = local.running_servers
  zone_id = local.zone.id
  name    = "${each.key}.servers.aws.${local.zone.name}"
  type    = "A"
  ttl     = "60"
  records  = [ each.value ]
}

// *.fk.private

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
  records = [ var.infrastructure.address ]
}

resource "aws_route53_record" "private-metrics" {
  zone_id = aws_route53_zone.private.id
  name    = "metrics.${aws_route53_zone.private.name}"
  type    = "A"
  ttl     = "300"
  records = [ var.infrastructure.address ]
}

resource "aws_route53_record" "private-db" {
  zone_id  = aws_route53_zone.private.id
  name     = "db.${aws_route53_zone.private.name}"
  type     = "CNAME"
  ttl      = "60"
  records  = [ local.database_address ]
}

resource "aws_route53_record" "private-servers" {
  for_each = local.running_servers
  zone_id  = aws_route53_zone.private.id
  name     = "${each.key}.${aws_route53_zone.private.name}"
  type     = "A"
  ttl      = "60"
  records  = [ each.value ]
}
