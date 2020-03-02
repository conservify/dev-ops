#!/bin/bash

pushd ssl

dir=`pwd`/letsencrypt

mkdir -p $dir

docker run \
	   --rm \
	   -v "$dir:/etc/letsencrypt/" \
	   -v "$HOME/.aws/:/root/.aws:ro" \
	   -e AWS_PROFILE \
	   -e AWS_ACCESS_KEY_ID \
	   -e AWS_SECRET_ACCESS_KEY \
	   danihodovic/certbot-route53 -d fkdev.org -d www.fkdev.org -d portal.fkdev.org -d api.fkdev.org -m jacob@conservify.org

docker run \
	   --rm \
	   -v "$dir:/etc/letsencrypt/" \
	   -v "$HOME/.aws/:/root/.aws:ro" \
	   -e AWS_PROFILE \
	   -e AWS_ACCESS_KEY_ID \
	   -e AWS_SECRET_ACCESS_KEY \
	   danihodovic/certbot-route53 -d fieldkit.org -d www.fieldkit.org -d portal.fieldkit.org -d api.fieldkit.org -m jacob@conservify.org

# echo ../bin/terraform plan
# echo ../bin/terraform apply

# echo make dev plan apply
# echo make prod plan apply

popd
