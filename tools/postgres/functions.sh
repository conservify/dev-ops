#!/bin/bash

LIVE_RD="postgres://$RD_LIVE_USER:${PASSWORD}@$RD_LIVE_HOST/fk"
LIVE_TS="postgres://$TS_LIVE_USER:${PASSWORD}@$TS_LIVE_HOST/fk"

PG13_ADMIN_URL="postgres://postgres:${PASSWORD}@$DB_PG13_HOST/postgres"
PG16_ADMIN_URL="postgres://postgres:${PASSWORD}@$DB_PG16_HOST/postgres"

PG13_FK_URL="postgres://postgres:${PASSWORD}@$DB_PG13_HOST/fk"
PG16_FK_URL="postgres://postgres:${PASSWORD}@$DB_PG16_HOST/fk"

cat <<EOF >pgpass
$RD_LIVE_HOST:5432:postgres:postgres:$PASSWORD
$RD_LIVE_HOST:5432:postgres:fk:$PASSWORD
$RD_LIVE_HOST:5432:fk:fk:$PASSWORD
$TS_LIVE_HOST:5432:postgres:postgres:$PASSWORD
$TS_LIVE_HOST:5432:fk:postgres:$PASSWORD
$DB_PG13_HOST:5432:postgres:postgres:$PASSWORD
$DB_PG13_HOST:5432:fk:postgres:$PASSWORD
$DB_PG16_HOST:5432:postgres:postgres:$PASSWORD
$DB_PG16_HOST:5432:fk:postgres:$PASSWORD
127.0.0.1:5432:postgres:postgres:$PASSWORD
127.0.0.1:5432:fk:postgres:$PASSWORD
EOF

function pg13_run() {
	ssh $DB_PG13_HOST $@
}

function pg16_run() {
	ssh $DB_PG16_HOST $@
}

function tsdb_fk_psql() {
	echo $1
	ssh $DB_PG13_HOST psql -h $TS_LIVE_HOST -U $TS_LIVE_USER -d fk -c "\"$1\""
}

function rds_psql {
	ssh $DB_PG16_HOST psql -h $RD_LIVE_HOST -U $RD_LIVE_USER -c "\"$1\""
}

function pg13_admin_psql {
	ssh $DB_PG13_HOST psql -h $DB_PG13_HOST -U $DB_PG13_USER -c "\"$1\""
}

function pg13_fk_psql {
	ssh $DB_PG13_HOST psql -h $DB_PG13_HOST -U $DB_PG13_USER -d fk -c "\"$1\""
}

function pg13_dump_running {
	ssh $DB_PG13_HOST time pg_dump -U $TS_LIVE_USER -h $TS_LIVE_HOST -d fk -Z0 -j2 -Fd -f $1
}

function pg16_admin_psql {
	ssh $DB_PG13_HOST psql -h $DB_PG16_HOST -U $DB_PG16_USER -c "\"$1\""
}

function pg16_fk_psql {
	ssh $DB_PG13_HOST psql -h $DB_PG16_HOST -U $DB_PG16_USER -d fk -c "\"$1\""
}

function pg13_restore_tsdb {
	# Do not use pg_restore with the -j option. This option does not correctly restore the TimescaleDB catalogs.
	ssh $DB_PG13_HOST time pg_restore -U $DB_PG13_USER -h $DB_PG13_HOST -d fk -Fd -j1 $1
}

function pg13_dump_for_pg16 {
	ssh $DB_PG16_HOST time pg_dump -U $DB_PG13_USER -h $DB_PG13_HOST -d fk -Z0 -j2 -Fd -f $1
}

function pg16_restore_tsdb {
	# Do not use pg_restore with the -j option. This option does not correctly restore the TimescaleDB catalogs.
	ssh $DB_PG16_HOST time pg_restore -U $DB_PG16_USER -h $DB_PG16_HOST -d fk -Fd -j1 $1
}

function rds_dump {
	ssh $DB_PG16_HOST time pg_dump -U $RD_LIVE_USER -h $RD_LIVE_HOST -d fk -Z0 -j2 -Fd -f $1
}

function pg16_restore_rds {
	ssh $DB_PG16_HOST time pg_restore -U $DB_PG16_USER -h $DB_PG16_HOST -d fk -Fd -j2 $1
}

# eof
