#!/bin/bash

. ./functions.sh

if [ -z "$STAMP" ]; then
	STAMP=$(date +"%Y%m%d_%H%M%S")
fi

set -xe

BACKUP="/svr0/migration/pg13-tsdb2.4.2-$STAMP-bak"

if true; then
	tsdb_fk_psql "SELECT _timescaledb_internal.stop_background_workers();"
	date
	pg13_dump_running $BACKUP
	tsdb_fk_psql "SELECT _timescaledb_internal.start_background_workers();"
fi

ssh $DB_PG13_HOST ls -alh /svr0/migration/

if true; then
	pg13_admin_psql "DROP DATABASE fk" || true
	pg13_admin_psql "CREATE DATABASE fk"
	pg13_fk_psql "CREATE EXTENSION postgis"
	pg13_fk_psql "CREATE EXTENSION timescaledb WITH VERSION '2.4.2'"
	pg13_fk_psql "SELECT timescaledb_pre_restore()"
	date
	pg13_restore_tsdb $BACKUP
	pg13_fk_psql "SELECT timescaledb_post_restore()"
fi

if true; then
	pg13_fk_psql "ALTER EXTENSION timescaledb UPDATE TO '2.15.3'"
	# Avoid deprecation warning and use new schema.
	# pg13_fk_psql "SELECT _timescaledb_internal.stop_background_workers()"
	pg13_fk_psql "SELECT _timescaledb_functions.stop_background_workers()"
fi

BACKUP="/svr0/migration/pg13-tsdb2.15.3-$STAMP-bak"

if true; then
	pg13_dump_for_pg16 $BACKUP
fi

if true; then
	pg16_fk_psql "SELECT timescaledb_pre_restore()"
	date
	pg16_restore_tsdb $BACKUP
	pg16_fk_psql "SELECT timescaledb_post_restore()"
	pg16_fk_psql "ALTER TABLE migrations RENAME TO migrations_tsdb"
	pg16_fk_psql "ALTER SEQUENCE migrations_id_seq RENAME TO migrations_id_seq_rds"
	pg16_fk_psql "ALTER TABLE migration_lock RENAME TO migration_lock_tsdb"
fi

# eof
