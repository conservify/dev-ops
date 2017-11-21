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

cat $FK_CLOUD_ROOT/schema/000001.sql $FK_CLOUD_ROOT/schema/000010-fixture-testing.sql > schema.sql
scp schema.sql core@$APP_SERVER_ADDRESS:schema.sql
rm schema.sql
ssh -t core@$APP_SERVER_ADDRESS "docker run -i --rm postgres psql $ENV_DB_URL < schema.sql"
