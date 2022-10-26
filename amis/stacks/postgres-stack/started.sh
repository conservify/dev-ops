#!/bin/bash

source /etc/user_data.env

for i in {1..30}; do
  sleep 1

  docker exec -i postgres-stack_postgres_1 psql -U postgres -v "ON_ERROR_STOP=1" <<EOF
ALTER USER postgres WITH PASSWORD '${FIELDKIT_POSTGRES_DB_PASSWORD}';
EOF

  if [ $? -eq 0 ]; then
    exit 0
  else
    echo "trying again..."
  fi
done
