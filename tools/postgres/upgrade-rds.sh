#!/bin/bash

. ./functions.sh

STAMP=$(date +"%Y%m%d_%H%M%S")

set -xe

BACKUP="/svr0/migration/pg16-rds-$STAMP-bak"

if true; then
	date
	rds_dump $BACKUP # 12m
fi

if true; then
	date
	pg16_restore_rds $BACKUP
	pg16_fk_psql "ALTER TABLE migrations RENAME TO migrations_rds"
	pg16_fk_psql "ALTER SEQUENCE migrations_id_seq RENAME TO migrations_id_seq_rds"
	pg16_fk_psql "ALTER TABLE migration_lock RENAME TO migration_lock_rds"
fi
