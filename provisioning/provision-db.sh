#!/bin/bash

set -xe

if [ -z "$ENV_DB_URL" ]; then
    echo "Please source setup-env.sh"
    exit 2
fi

echo "Starting ssh-agent..."
eval $(ssh-agent)
trap "ssh-agent -k" exit
ssh-add ~/.ssh/cfy.pem

scp ../../fk-cloud/schema/000001.sql core@$APP_SERVER_ADDRESS:schema.sql
ssh -t core@$APP_SERVER_ADDRESS "docker run -i --rm postgres psql $ENV_DB_URL < schema.sql"
