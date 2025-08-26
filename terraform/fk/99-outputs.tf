output bare_ami_id {
  value = data.aws_ami.bare.id
}

output postgres_ami_id {
  value = data.aws_ami.postgres-16.id
}

output tsdb_snapshot_id {
  value = data.aws_ebs_snapshot.tsdb_snapshot.id
}

output database_url {
  value = local.database_url
  sensitive = true
}

output database_admin_url {
  value = local.database_admin_url
  sensitive = true
}

output database_address {
  value = local.database_address
}

output database_username {
  value = local.database.username
}

output database_password {
  value = local.database.password
  sensitive = true
}

output timescaledb_url {
  value = local.timescaledb_url
  sensitive = true
}

output timescaledb_admin_url {
  value = local.timescaledb_admin_url
  sensitive = true
}

output timescaledb_address {
  value = local.timescaledb_address
  sensitive = true
}

output timescaledb_username {
  value = local.timescaledb_username
  sensitive = true
}

output timescaledb_password {
  value = local.timescaledb_password
  sensitive = true
}

output influxdb_servers {
  value = [
    for key, i in aws_instance.influxdb_servers: {
      id = i.id
      key = key
      user = "ubuntu"
      ip = i.private_ip
      sshAt = "ubuntu@${i.private_ip}"
    }
  ]
}

output servers {
  value = [
    for key, i in aws_instance.app-servers: {
      id = i.id
      key = key
      user = "ubuntu"
      ip = i.private_ip
      sshAt = "ubuntu@${i.private_ip}"
      live = local.app_servers[key].config.live
      deploy = local.app_servers[key].config.deploy
    }
  ]
}

output alb {
  value = {
    id: aws_alb.app-servers.id,
    listeners: {
      http: aws_alb_listener.app-servers-80.id,
      https: aws_alb_listener.app-servers-443.id
    }
  }
}
