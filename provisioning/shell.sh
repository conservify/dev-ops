#!/bin/bash

set -xe

if [ -z "$ENV_DB_URL" ]; then
    source ./setup-env.sh
fi
if [ -z "$ENV_DB_URL" ]; then
    echo No cloud configuration.
    exit 2
fi

echo "Starting ssh-agent..."
eval $(ssh-agent)
trap "ssh-agent -k" exit
ssh-add ~/.ssh/cfy.pem

ssh -t core@$APP_SERVER_ADDRESS 
