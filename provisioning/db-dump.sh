#!/bin/bash

if [ -z "$ENV_DB_URL" ]; then
    source ./setup-env.sh
fi
if [ -z "$ENV_DB_URL" ]; then
    echo No cloud configuration.
    exit 2
fi

ssh -t fkdev "docker run -it --rm postgres pg_dump -s $ENV_DB_URL > schema.sql"
ssh -t fkdev "docker run -it --rm postgres pg_dump -a $ENV_DB_URL --exclude-table-data fieldkit.inaturalist_observations > data.sql"
rsync -zvua --progress "fkdev:*.sql" ../
