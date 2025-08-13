locals {
  timescaledb_name = local.database.name
  timescaledb_address = "postgres-servers.aws.${local.zone.name}"
  timescaledb_username = "postgres"
  timescaledb_password = local.database.password
  timescaledb_url = "postgres://${local.timescaledb_username}:${local.timescaledb_password}@${local.timescaledb_address}/${local.timescaledb_name}?sslmode=disable"
  timescaledb_admin_url = "postgres://${local.timescaledb_username}:${local.timescaledb_password}@${local.timescaledb_address}/postgres?sslmode=disable"
  prod = terraform.workspace == "prod"
}

data "aws_ebs_snapshot" "tsdb_snapshot" {
  owners = ["self"]
  most_recent = true

  filter {
    name = "tag:Env"
    values = [ "fkprd" ]
  }
  filter {
    name = "tag:PostgresBackup"
    values = [ "true" ]
  }
}

data "template_file" "postgres_server_user_data" {
  for_each                    = local.postgres_servers
  template                    = file("user_data_postgres.yaml")

  vars = {
    hostname                  = each.value.name
    zone_name                 = local.zone.name
    env_tag                   = local.env

    postgres_password         = local.database.password

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

resource "aws_instance" "postgres_servers" {
  for_each                    = local.postgres_servers
  ami                         = data.aws_ami.bare.id
  subnet_id                   = aws_subnet.private[each.value.zone].id
  instance_type               = each.value.config.instance
  vpc_security_group_ids      = [ aws_security_group.ssh.id, aws_security_group.postgres-server.id ]
  user_data                   = data.template_file.postgres_server_user_data[each.key].rendered
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
    tags = {
      Name = "${each.value.name} root"
    }
  }

  tags = {
    Name = "${each.value.name}"
  }
}

// Would love change the names here, perhaps to postgres_data_svr0 and I'd also like to get rid of the "from_snapshot" item.

resource "aws_ebs_volume" "postgres_data" {
  for_each          = local.prod ? local.postgres_servers : {}
  size              = 300
  encrypted         = true
  type              = "io1"
  iops              = 4000
  availability_zone = each.value.zone

  tags = {
    Name = "${each.value.name} svr0"
    Snapshot = local.env
  }
}

resource "aws_ebs_volume" "postgres_data_from_snapshot" {
  for_each          = local.prod ? {} : local.postgres_servers
  size              = 800
  encrypted         = true
  type              = "io1"
  iops              = 4000
  availability_zone = each.value.zone
  snapshot_id       = data.aws_ebs_snapshot.tsdb_snapshot.id

  lifecycle {
    ignore_changes  = [ snapshot_id ]
  }

  tags = {
    Name = "${each.value.name} svr0"
    Snapshot = local.env
  }
}

resource "aws_volume_attachment" "postgres_data_attach" {
  for_each                       = { for key, value in aws_instance.postgres_servers: key => value }
  device_name                    = "/dev/xvdh"
  volume_id                      = local.prod ? aws_ebs_volume.postgres_data[each.key].id : aws_ebs_volume.postgres_data_from_snapshot[each.key].id
  instance_id                    = each.value.id
  force_detach                   = true
  stop_instance_before_detaching = true
}    

resource "aws_ebs_volume" "postgres_data_svr1" {
  for_each          = local.prod ? local.postgres_servers : {}
  size              = 500
  encrypted         = true
  type              = "io1"
  iops              = 4000
  availability_zone = each.value.zone

  tags = {
    Name = "${each.value.name} svr1"
    Snapshot = local.env
  }
}

resource "aws_volume_attachment" "postgres_data_attach_svr1" {
  for_each                       = local.prod ? { for key, value in aws_instance.postgres_servers: key => value } : {}
  device_name                    = "/dev/xvdi"
  volume_id                      = aws_ebs_volume.postgres_data_svr1[each.key].id
  instance_id                    = each.value.id
  force_detach                   = true
  stop_instance_before_detaching = true
}    

resource "aws_dlm_lifecycle_policy" "postgres_data_lifecycle_policy" {
  description        = "DLM lifecycle policy for postgres_data"
  execution_role_arn = aws_iam_role.dlm_lifecycle_role.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = "2 weeks of daily snapshots"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["23:45"]
      }

      retain_rule {
        count = 14
      }

      tags_to_add = {
        SnapshotCreator = "DLM"
	      PostgresBackup = "true"
	      Env = local.env
      }

      copy_tags = false
    }

    target_tags = {
      Snapshot = local.env
    }
  }

  tags = {
    Name = "${local.env} postgres backup policy"
    Snapshot = local.env
  }
}

// --------------------------------------------------------------------------------------------------------------------
// Standby Servers
// --------------------------------------------------------------------------------------------------------------------

data "template_file" "postgres_standby_server_user_data" {
  for_each                    = local.postgres_standby_servers
  template                    = file("user_data_postgres.yaml")

  vars = {
    hostname                  = each.value.name
    zone_name                 = local.zone.name
    env_tag                   = local.env

    postgres_password         = local.database.password

    aws_access_key            = var.access_key
    aws_secret_key            = var.secret_key

    gelf_url                  = var.gelf_url
    statsd_address            = var.statsd_address
    metrics_influxdb_url      = var.metrics_influxdb.url
    metrics_influxdb_database = var.metrics_influxdb.name
    metrics_influxdb_user     = var.metrics_influxdb.user
    metrics_influxdb_password = var.metrics_influxdb.password

    application_stacks        = ""

    production                = local.production
  }
}

resource "aws_instance" "postgres_standby_servers" {
  for_each                    = local.postgres_standby_servers
  ami                         = data.aws_ami.postgres.id
  subnet_id                   = aws_subnet.private[each.value.zone].id
  instance_type               = each.value.config.instance
  vpc_security_group_ids      = [ aws_security_group.ssh.id, aws_security_group.postgres-server.id ]
  user_data                   = data.template_file.postgres_standby_server_user_data[each.key].rendered
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
    tags = {
      Name = "${each.value.name} root"
    }
  }

  tags = {
    Name = "${each.value.name}"
  }
}

resource "aws_ebs_volume" "postgres_standby_data_svr0" {
  for_each          = local.postgres_standby_servers
  size              = 1000
  encrypted         = true
  type              = "io1"
  iops              = 4000
  availability_zone = each.value.zone

  tags = {
    Name = "${each.value.name} svr0"
    Snapshot = local.env
  }
}

resource "aws_volume_attachment" "postgres_standby_data_attach_svr0" {
  for_each                       = { for key, value in aws_instance.postgres_standby_servers: key => value }
  device_name                    = "/dev/xvdh"
  volume_id                      = aws_ebs_volume.postgres_standby_data_svr0[each.key].id
  instance_id                    = each.value.id
  force_detach                   = true
  stop_instance_before_detaching = true
}    
