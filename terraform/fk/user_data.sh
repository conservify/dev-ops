#!/bin/bash

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

END

cp /etc/user_data.env /etc/default/telegraf

for directory in /etc/docker/compose/*; do
	cp /etc/user_data.env $directory/99_user_data.env
done
