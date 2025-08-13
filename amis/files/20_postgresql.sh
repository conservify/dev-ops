#!/bin/bash

set -xu

# Enable accepting remote connections.
sed -i "s@#listen_addresses = 'localhost'@listen_addresses = '*'@g" /etc/postgresql/17/main/postgresql.conf

# Shared library for TimescaleDb
cat <<EOF >> /etc/postgresql/17/main/postgresql.conf
shared_preload_libraries = 'timescaledb'
EOF

# Enable password authentication for remote hosts.
cat <<EOF >> /etc/postgresql/17/main/pg_hba.conf
# Password authentication for remote hosts.
host    all             all             0.0.0.0/0               scram-sha-256
EOF

