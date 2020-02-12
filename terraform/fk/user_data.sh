#!/bin/bash

# Write our glorious configuration to a local file then we then push
# to various other services.

cat > /etc/user_data.env <<END
HOSTNAME=${hostname}
ZONE_NAME=${zone_name}
GELF_URL=${gelf_url}
GELF_TAGS=${gelf_tags}
ENV_TAG=${env_tag}

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

# Basic setup and pull down any application stack we've been given.

source /etc/user_data.env

hostname $HOSTNAME

for directory in /etc/docker/compose/*; do
	cp /etc/user_data.env $directory/99_user_data.env
	cat $directory/*_*.env > $directory/.env
done

cp /etc/user_data.env /etc/default/telegraf
