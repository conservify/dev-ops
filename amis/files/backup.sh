#!/bin/bash

source /etc/user_data.env

set -xe

WORK=/svr0/work
DATA=/svr0/data
STAMP=$(date +"%Y%m%d_%H%M%S")
BASE=${STAMP}_backup.sql
SENSOR_DATA=${STAMP}_sensor_data.sql
BOOKMARKS=${STAMP}_bookmarks.sql

pushd $WORK

# /var/lib/conservify/sanitizer

time pg_dump -v -j1 -d fk \
        --exclude-table-data='_timescaledb_internal._hyper*' \
        --exclude-table-data='fieldkit.ttn_messages' \
        --exclude-table-data='fieldkit.data_record' \
        --exclude-table-data='fieldkit.bookmarks' \
        > $BASE

echo "COPY fieldkit.sensor_data FROM STDIN;" > $SENSOR_DATA
time psql -d fk -c "COPY (SELECT * FROM fieldkit.sensor_data WHERE time > NOW() - '7 days'::interval) TO STDOUT" >> $SENSOR_DATA

time pg_dump -v -j1 -d fk -t 'fieldkit.bookmarks' > $BOOKMARKS

ls -alh

time xz $BASE
time xz $SENSOR_DATA
time xz $BOOKMARKS

mv *.xz $DATA

popd
