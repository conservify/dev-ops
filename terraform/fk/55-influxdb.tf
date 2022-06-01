data "template_file" "influxdb_server_user_data" {
  for_each                    = local.influxdb_servers
  template                    = file("user_data_influxdb.yaml")

  vars = {
    hostname                  = each.value.name
    zone_name                 = local.zone.name
    env_tag                   = local.env

    aws_access_key            = var.access_key
    aws_secret_key            = var.secret_key

    gelf_url                  = var.gelf_url
    statsd_address            = var.statsd_address
    metrics_influxdb_url      = var.metrics_influxdb.url
    metrics_influxdb_database = var.metrics_influxdb.name
    metrics_influxdb_user     = var.metrics_influxdb.user
    metrics_influxdb_password = var.metrics_influxdb.password

    application_stacks        = join(",", each.value.config.stacks)

    production                = local.production
  }
}

resource "aws_instance" "influxdb_servers" {
  for_each                    = local.influxdb_servers
  ami                         = data.aws_ami.bare.id
  subnet_id                   = aws_subnet.private[each.value.zone].id
  instance_type               = each.value.config.instance
  vpc_security_group_ids      = [ aws_security_group.ssh.id, aws_security_group.influxdb-server.id ]
  user_data                   = data.template_file.influxdb_server_user_data[each.key].rendered
  monitoring                  = true
  associate_public_ip_address = false
  key_name                    = "cfy-dev-server"
  iam_instance_profile        = aws_iam_instance_profile.fk-server.id
  availability_zone           = each.value.zone

  lifecycle {
    ignore_changes = [ ami, user_data ]
    create_before_destroy = true
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = 100
  }

  tags = {
    Name = "${each.value.name}"
  }
}

resource "aws_ebs_volume" "influxdb_data" {
  for_each          = local.influxdb_servers
  size              = 300
  encrypted         = true
  type              = "io1"
  iops              = 4000
  availability_zone = each.value.zone
}

resource "aws_volume_attachment" "influxdb_data_attach" {
  for_each          = { for key, value in aws_instance.influxdb_servers: key => value }
  device_name       = "/dev/xvdh"
  volume_id         = aws_ebs_volume.influxdb_data[each.key].id
  instance_id       = each.value.id
  force_detach      = true
}
