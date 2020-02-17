#!/bin/bash

if [ -z "$ENV_DB_URL" ]; then
    source ./setup-env.sh
fi
if [ -z "$ENV_DB_URL" ]; then
    echo No cloud configuration.
    exit 2
fi

ssh -t fkdev "docker run -it --rm postgres psql $ENV_DB_URL"
