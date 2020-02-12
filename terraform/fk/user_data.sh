#!/bin/bash

cat > /etc/conservify.env <<END

HOSTNAME=${hostname}
ZONE_NAME=${zone_name}
GELF_ADDRESS=${gelf_address}
GELF_TAGS=${gelf_tags}

DATABASE_URL=${database_url}

INFLUX_URL=${influx_url}
INFLUX_DATABASE=${influx_database}
INFLUX_USER=${influx_user}
INFLUX_PASSWORD=${influx_password}

AWS_ACCESS_KEY=${aws_access_key}
AWS_SECRET_KEY=${aws_secret_key}

END

cp /etc/conservify.env /etc/default/telegraf
cp /etc/conservify.env /etc/default/docker-compose
cp /etc/conservify.env /etc/docker/compose
