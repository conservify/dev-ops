
resource "aws_route53_record" "fk-server-a" {
  zone_id = "${var.zone_id}"
  name    = "fk-server-a.aws.${var.zone_name}"
  type    = "A"
  ttl     = "60"
  records = ["${aws_instance.fk-app-server-a.public_ip}"]
}

resource "aws_route53_record" "home" {
  zone_id = "${var.zone_id}"
  name    = "${var.zone_name}"
  type    = "A"

  alias {
    name                   = "${aws_alb.fk-server.dns_name}"
    zone_id                = "${aws_alb.fk-server.zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "api-data" {
  zone_id = "${var.zone_id}"
  name    = "api.${var.zone_name}"
  type    = "A"

  alias {
    name                   = "${aws_alb.fk-server.dns_name}"
    zone_id                = "${aws_alb.fk-server.zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "wildcard" {
  zone_id = "${var.zone_id}"
  name    = "*.${var.zone_name}"
  type    = "A"

  alias {
    name                   = "${aws_alb.fk-server.dns_name}"
    zone_id                = "${aws_alb.fk-server.zone_id}"
    evaluate_target_health = false
  }
}
