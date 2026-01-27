#!/bin/bash

source /etc/user_data.env

set -xe

WORK=/svr0/work
DATA=/svr0/data
STAMP=$(date +"%Y%m%d_%H%M%S")
BASE=${STAMP}_backup.sql
SENSOR_DATA_21=${STAMP}_sensor_data_21d.sql
SENSOR_DATA_42=${STAMP}_sensor_data_42d.sql
BOOKMARKS=${STAMP}_bookmarks.sql

pushd $WORK

time pg_dump -v -j1 -d fk \
        --exclude-table-data='_timescaledb_internal._hyper*' \
        --exclude-table-data='fieldkit.ttn_messages' \
        --exclude-table-data='fieldkit.data_record' \
        --exclude-table-data='fieldkit.bookmarks' \
        > $BASE

time xz $BASE
mv *.xz $DATA


echo "COPY fieldkit.sensor_data FROM STDIN;" > $SENSOR_DATA_21
time psql -d fk -c "COPY (SELECT * FROM fieldkit.sensor_data WHERE time > NOW() - '21 days'::interval) TO STDOUT" >> $SENSOR_DATA_21
time xz $SENSOR_DATA_21
mv *.xz $DATA


echo "COPY fieldkit.sensor_data FROM STDIN;" > $SENSOR_DATA_42
time psql -d fk -c "COPY (SELECT * FROM fieldkit.sensor_data WHERE time > NOW() - '42 days'::interval) TO STDOUT" >> $SENSOR_DATA_42
time xz $SENSOR_DATA_42
mv *.xz $DATA


time pg_dump -v -j1 -d fk -t 'fieldkit.bookmarks' > $BOOKMARKS
time xz $BOOKMARKS
mv *.xz $DATA

ls -alh

popd
