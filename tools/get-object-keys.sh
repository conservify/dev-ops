#!/bin/bash

set -e

source aws.env

rm -f fk-prod*.csv fk-staging*.csv

docker run -it --rm postgres psql "$PRODUCTION" -c "COPY fieldkit.ingestion TO STDOUT WITH CSV HEADER" > fk-prod-ingestion.csv
docker run -it --rm postgres psql "$PRODUCTION" -c "COPY fieldkit.firmware TO STDOUT WITH CSV HEADER" > fk-prod-firmware.csv
docker run -it --rm postgres psql "$PRODUCTION" -c "COPY fieldkit.user TO STDOUT WITH CSV HEADER" > fk-prod-user.csv
docker run -it --rm postgres psql "$PRODUCTION" -c "COPY fieldkit.project TO STDOUT WITH CSV HEADER" > fk-prod-project.csv
docker run -it --rm postgres psql "$PRODUCTION" -c "COPY fieldkit.field_note_media TO STDOUT WITH CSV HEADER" > fk-prod-fnm.csv

docker run -it --rm postgres psql "$STAGING"    -c "COPY fieldkit.ingestion TO STDOUT WITH CSV HEADER" > fk-staging-ingestion.csv
docker run -it --rm postgres psql "$STAGING"    -c "COPY fieldkit.firmware TO STDOUT WITH CSV HEADER" > fk-staging-firmware.csv
docker run -it --rm postgres psql "$STAGING"    -c "COPY fieldkit.user TO STDOUT WITH CSV HEADER" > fk-staging-user.csv
docker run -it --rm postgres psql "$STAGING"    -c "COPY fieldkit.project TO STDOUT WITH CSV HEADER" > fk-staging-project.csv
docker run -it --rm postgres psql "$STAGING"    -c "COPY fieldkit.field_note_media TO STDOUT WITH CSV HEADER" > fk-staging-fnm.csv
