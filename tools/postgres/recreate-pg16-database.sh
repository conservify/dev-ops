#!/bin/bash

. ./functions.sh

set -xe

if true; then
	pg16_admin_psql "DROP DATABASE fk" || true
	pg16_admin_psql "CREATE DATABASE fk"
	pg16_fk_psql "DROP USER fk" || true
	pg16_fk_psql "DROP USER server" || true
	pg16_fk_psql "DROP USER fieldkit" || true
	pg16_fk_psql "CREATE USER fk WITH PASSWORD '$PASSWORD'"
	pg16_fk_psql "CREATE USER server WITH PASSWORD '$PASSWORD'"
	pg16_fk_psql "CREATE USER fieldkit WITH PASSWORD '$PASSWORD'"
	pg16_fk_psql "CREATE EXTENSION postgis"
	pg16_fk_psql "CREATE EXTENSION timescaledb WITH VERSION '2.15.3'"
	pg16_admin_psql 'ALTER DATABASE \"fk\" SET search_path TO \"\$user\", fieldkit, public'
fi

