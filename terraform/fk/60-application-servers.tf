data "aws_ami" "bare" {
  owners           = ["self"]
  name_regex       = "^conservify-bare-.*"
  most_recent      = true
}

data "template_file" "app_server_user_data" {
  for_each                    = local.servers
  template                    = file("user_data.yaml")

  vars = {
	hostname                  = each.value.name
	zone_name                 = local.zone.name
	env_tag                   = local.env

	aws_access_key            = var.access_key
	aws_secret_key            = var.secret_key

	mapbox_token              = local.tokens.mapbox

	gelf_url                  = var.gelf_url
	statsd_address            = var.statsd_address

	influx_url                = var.influx_database.url
	influx_database           = var.influx_database.name
	influx_user               = var.influx_database.user
	influx_password           = var.influx_database.password

	application_start         = each.value.config.start
	application_stack         = each.value.config.stack

	database_url              = local.database_url
	database_address          = local.database_address
	database_username         = local.database.username
	database_password         = local.database.password

	streams_bucket_name       = local.buckets.streams
	media_bucket_name         = local.buckets.media

	email_override            = local.email_override
	production                = local.production

	session_key               = local.session_key

    # saml_cert               = local.saml.cert
    # saml_key                = local.saml.key
    saml_sp_url               = local.saml.sp_url
    saml_ipd_meta             = local.saml.ipd_url
	saml_login_url            = local.saml.login_url

    keycloak_url_private      = local.keycloak.urls.private
    keycloak_url_public       = local.keycloak.urls.public
    keycloak_realm            = local.keycloak.realm
    keycloak_admin_user       = local.keycloak.admin_user
    keycloak_admin_password   = local.keycloak.admin_password
    keycloak_api_user         = local.keycloak.api_user
    keycloak_api_password     = local.keycloak.api_password
	keycloak_api_realm        = local.keycloak.api_realm

	discourse_secret          = local.discourse.secret
	discourse_admin_key       = local.discourse.admin_key
	discourse_return_url      = local.discourse.return_url

	oidc_client_id            = local.oidc.client_id
	oidc_client_secret        = local.oidc.client_secret
	oidc_return_url           = local.oidc.return_url
	oidc_config_url           = local.oidc.config_url

	saml_cert_data            = filebase64(local.saml.cert)
	saml_key_data             = filebase64(local.saml.key)
  }
}

resource "aws_instance" "app-servers" {
  for_each                    = local.servers
  depends_on                  = [aws_internet_gateway.fk]
  ami                         = data.aws_ami.bare.id
  subnet_id                   = aws_subnet.private[each.value.zone].id
  instance_type               = each.value.config.instance
  vpc_security_group_ids      = [ aws_security_group.ssh.id, aws_security_group.fk-app-server.id ]
  user_data                   = data.template_file.app_server_user_data[each.key].rendered
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
