#!/bin/bash

PG_VERSION_MAJOR=16

set -xu

# Enable accepting remote connections.
sed -i "s@#listen_addresses = 'localhost'@listen_addresses = '*'@g" /etc/postgresql/$PG_VERSION_MAJOR/main/postgresql.conf

# Shared library for TimescaleDb
cat <<EOF >> /etc/postgresql/$PG_VERSION_MAJOR/main/postgresql.conf
shared_preload_libraries = 'timescaledb'
EOF

# Enable password authentication for remote hosts.
cat <<EOF >> /etc/postgresql/$PG_VERSION_MAJOR/main/pg_hba.conf
# Password authentication for remote hosts.
host    all             all             0.0.0.0/0               scram-sha-256
EOF

# Enable password authentication for replication hosts. Technically the above should pass them through, just in case.
# I would love to have subnet information here.
cat <<EOF >> /etc/postgresql/$PG_VERSION_MAJOR/main/pg_hba.conf
# Password authentication for remote hosts.
host    replication     all             0.0.0.0/0               scram-sha-256
EOF

