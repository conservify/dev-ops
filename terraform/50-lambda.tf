module "lambda-api" {
  source = "./lambda-api"

  region   = "${var.region}"
  owner_id = "${data.aws_caller_identity.current.account_id}"
}
