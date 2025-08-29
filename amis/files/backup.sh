#!/bin/bash

source /etc/user_data.env

set -xe

STAMP=$(date +"%Y%m%d_%H%M%S")
FILE=/svr0/work/${STAMP}_backup.sql

# /var/lib/conservify/sanitizer

time pg_dump -v -j1 -d fk \
        --exclude-table-data='_timescaledb_internal._hyper*' \
        --exclude-table-data='fieldkit.ttn_messages' \
        --exclude-table-data='fieldkit.data_record' \
        --exclude-table-data='fieldkit.bookmarks' \
        > $FILE

echo >> $FILE
echo >> $FILE
echo "COPY fieldkit.sensor_data FROM STDIN;" >> $FILE
time psql -d fk -c "COPY (SELECT * FROM fieldkit.sensor_data WHERE time > NOW() - '7 days'::interval) TO STDOUT" >> $FILE

ls -alh /svr0/work

time xz $FILE

mv *.xz /svr0/data
