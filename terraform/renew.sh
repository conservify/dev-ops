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


# Right now this will successfully renew the certificates. Unfortunately the
# way things are, it's tricky getting this to update the ELBs so I've been
# doing this manually

# Login to the EC2 Console and then go to the ELB and Edit the listener to
# change the default certificate. Then you can run the plan again to delete the
# old certificates.

popd
