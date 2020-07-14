output bare_ami_id {
  value = data.aws_ami.bare.id
}

output database_url {
  value = local.database_url
  sensitive = true
}

output servers {
  value = [
	for key, i in aws_instance.app-servers: {
	  id = i.id
	  key = key
	  user = "ubuntu"
	  ip = i.private_ip
	  sshAt = "ubuntu@${i.private_ip}"
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

output user_data {
  value = [
	for key, i in data.template_file.app_server_user_data: {
	  key = key
	  value = data.template_file.app_server_user_data[key].rendered
	}
  ]
}
