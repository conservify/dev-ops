#!/bin/bash

source /etc/user_data.env

set -xe

WORK=/svr0/work
DATA=/svr0/data
STAMP=$(date +"%Y%m%d_%H%M%S")
FILE=${STAMP}_backup.sql

pushd $WORK

# /var/lib/conservify/sanitizer

time pg_dump -v -j1 -d fk \
        --exclude-table-data='_timescaledb_internal._hyper*' \
        --exclude-table-data='fieldkit.ttn_messages' \
        --exclude-table-data='fieldkit.data_record' \
        --exclude-table-data='fieldkit.bookmarks' \
        > $FILE

echo >> $FILE
echo "SELECT timescaledb_pre_restore();"
echo >> $FILE
echo "COPY fieldkit.sensor_data FROM STDIN;" >> $FILE
time psql -d fk -c "COPY (SELECT * FROM fieldkit.sensor_data WHERE time > NOW() - '7 days'::interval) TO STDOUT" >> $FILE
echo >> $FILE
echo "SELECT timescaledb_post_restore();"
echo >> $FILE

ls -alh

time xz $FILE

mv *.xz $DATA

popd
