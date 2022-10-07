#!/bin/bash

source /etc/user_data.env

echo "ALTER USER postgres WITH PASSWORD '${FIELDKIT_POSTGRES_DB_PASSWORD}';" | docker exec -i postgres-stack_postgres_1 psql -U postgres
