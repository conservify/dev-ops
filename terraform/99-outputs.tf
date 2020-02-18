output bare_ami_id {
  value = data.aws_ami.bare.id
}

output database_url {
  value = local.database_url
}

output servers {
  value = [
	for key, i in aws_instance.app-servers: {
	  key = key
	  id = i.id
	  ip = i.private_ip
	}
  ]
}
