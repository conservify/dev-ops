#!/bin/bash

. ./functions.sh

set -xe

if true; then
	scp pgpass $DB_PG13_HOST:.pgpass
	scp pgpass $DB_PG16_HOST:.pgpass

	scp prepare.sh $DB_PG13_HOST:
	scp prepare.sh $DB_PG16_HOST:

	echo preparing pg13...
	pg13_run ./prepare.sh
	echo done

	echo preparing pg16...
	pg16_run ./prepare.sh
	echo done
fi

if true; then
	echo verifying connections...
	tsdb_fk_psql "SELECT version()"
	rds_psql "SELECT version()"
	pg13_admin_psql "SELECT version()"
	pg16_admin_psql "SELECT version()"
	echo ready!
fi

