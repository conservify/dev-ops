variable region {
  type = string
  default = "us-east-1"
}

variable access_key {
  type = string
}

variable secret_key {
  type = string
}

variable workspace_tags {
  type = map(string)
}

variable workspace_tokens {
  type = map(object({
	mapbox = string
  }))
}

variable workspace_zones {
  type = map(object({
	id = string
	name = string
  }))
}

variable workspace_buckets {
  type = map(object({
	create = object({
	  streams = string
	  media = string
	})
	config = object({
	  streams = string
	  media = string
	})
  }))
}

variable workspace_databases {
  type = map(object({
	id = string
	name = string
	username = string
	password = string
	instance = string
	engine_version = string
	allocated_storage = number
  }))
}

variable workspace_influxdbs {
  type = map(object({
	username = string
	password = string
	org = string
	bucket = string
	token = string
  }))
}

variable bastions {
  // This crashes?
  /*
  type = map(object({
	name = string
	cidr = tuple([string])
  }))
  */
}

variable workspace_discourse {
  type = map(object({
	secret = string
	redirect_url = string
	admin_key = string
  }))
}

variable workspace_oidc {
  type = map(object({
	client_id = string
	client_secret = string
	config_url = string
	redirect_url = string
  }))
}

variable workspace_keycloak {
  type = map(object({
	urls = object({
	  public = string
	  private = string
	})
	realm = string
	admin_user = string
	admin_password = string
	api_user = string
	api_password = string
	api_realm = string
  }))
}

variable workspace_saml {
  type = map(object({
	cert = string
	key = string
	sp_url = string
	ipd_url = string
	login_url = string
  }))
}

variable gelf_url {
  type = string
}

variable statsd_address {
  type = string
  default = "172.17.0.1:8125"
}

variable metrics_influxdb {
  type = object({
	url = string
	name = string
	user = string
	password = string
  })
}

variable application_start {
  type = string
  default = ""
}

variable application_stack {
  default = ""
}

variable workspace_influxdb_servers {
  type = map(map(object({
	name = string
	number = number
	instance = string
	live = bool
	stacks = list(string)
  })))
}
variable workspace_servers {
  type = map(map(object({
	name = string
	number = number
	instance = string
	live = bool
	stacks = list(string)
  })))
}

variable workspace_networks {
  type = map(object({
	cidr = string
	peering = string
	azs = map(object({
	  public = string
	  private = string
	  gateway = bool
	}))
  }))
}

variable workspace_session_keys {
  type = map(string)
}

variable infrastructure {
  type = object({
	address = string
	cidr = string
	sg_id = string
  })
}

locals {
  network = var.workspace_networks[terraform.workspace]
  zones = keys(local.network.azs)

  all_influxdb_servers = flatten([
	for k, v in var.workspace_influxdb_servers[terraform.workspace] : [
	  for r in range(v.number) : {
		name = "${local.env}-${v.name}-${r}"
		number = r
		config = v
		zone = local.zones[r % length(local.zones)]
	  }
	]
  ])
  influxdb_servers = {
	for r in local.all_influxdb_servers : r.name => r
  }

  all_app_servers = flatten([
	for k, v in var.workspace_servers[terraform.workspace] : [
	  for r in range(v.number) : {
		name = "${local.env}-${v.name}-${r}"
		number = r
		config = v
		zone = local.zones[r % length(local.zones)]
	  }
	]
  ])
  servers = {
	for r in local.all_app_servers : r.name => r
  }

  zone = var.workspace_zones[terraform.workspace]
  partners = {
    floodnet = {
      zone = var.workspace_zones["floodnet.nyc"]
    }
  }
  env = var.workspace_tags[terraform.workspace]
  buckets = var.workspace_buckets[terraform.workspace]
  database = var.workspace_databases[terraform.workspace]
  influxdb = var.workspace_influxdbs[terraform.workspace]
  production = terraform.workspace == "prod" ? "true" : "false"
  email_override = terraform.workspace == "prod" ? "" : "fkdev@conservify.org"
  session_key = var.workspace_session_keys[terraform.workspace]
  tokens = var.workspace_tokens[terraform.workspace]
  keycloak = var.workspace_keycloak[terraform.workspace]
  saml = var.workspace_saml[terraform.workspace]
  discourse = var.workspace_discourse[terraform.workspace]
  oidc = var.workspace_oidc[terraform.workspace]
}
