#!/bin/bash

# Write our glorious configuration to a local file then we then push
# to various other services.

cat > /etc/user_data.env <<END
HOSTNAME=${hostname}
ZONE_NAME=${zone_name}
GELF_URL=${gelf_url}
GELF_TAGS=${env_tag}

DATABASE_URL=${database_url}

INFLUX_URL=${influx_url}
INFLUX_DATABASE=${influx_database}
INFLUX_USER=${influx_user}
INFLUX_PASSWORD=${influx_password}

AWS_ACCESS_KEY=${aws_access_key}
AWS_SECRET_KEY=${aws_secret_key}

APPLICATION_START=${application_start}
APPLICATION_STACK=${application_stack}
END

# Pull in configuration and do some basic setup.

source /etc/user_data.env

hostname $HOSTNAME

# Make sure the hostname is showing in the logs.

systemctl restart rsyslog

# Configure telegraf.

cp /etc/user_data.env /etc/default/telegraf

systemctl restart telegraf

# Look for any preconfigured stacks and give them the correct config.

for directory in /etc/docker/compose/*; do
	cp /etc/user_data.env $directory/99_user_data.env
	cat $directory/*_*.env > $directory/.env
done

# If we were given a stack to download, do that now and allow the
# maintenance servicing to install things.

if [ ! -z "$APPLICATION_STACK" ]; then
	mkdir -p /tmp/incoming-stacks
	mkdir -p /tmp/downloading-stacks
	pushd /tmp/downloading-stacks
	wget --auth-no-challenge $APPLICATION_STACK
	mv * /tmp/incoming-stacks
	popd
fi
