#!/bin/bash

set -xe

if [ -z "$APP_SERVER_ADDRESS" ]; then
    echo "Please source setup-env.sh"
    exit 2
fi

echo "Starting ssh-agent..."
eval $(ssh-agent)
trap "ssh-agent -k" exit
ssh-add ~/.ssh/cfy.pem

ssh -t core@$APP_SERVER_ADDRESS 
