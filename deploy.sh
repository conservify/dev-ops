#!/bin/bash

# We need the environment as well as the stack being deployed.
ENV=$1
STACK=$2

if [ -z "$ENV" ]; then
	echo "usage: deploy.sh ENV STACK"
	exit 2
fi

if [ -z "$STACK" ]; then
	echo "usage: deploy.sh ENV STACK"
	exit 2
fi

# These will rarely change.
export CARGO_HOME=~/.cargo
export PATH=$PATH:$CARGO_HOME/bin
export CERT=~/.ssh/deploy.pem
export PRIMARY_MIGRATIONS_PATH=~/dev-ops/deploy/primary
export TSDB_MIGRATIONS_PATH=~/dev-ops/deploy/tsdb

# Depends on environment and what's being deployed.
export ARCHIVE=~/dev-ops/deploy/${STACK}.tar
if [ "$ENV" == "prod" ]; then
	export TERRAFORM_ENV=~/dev-ops/prod.json
	export POLL_URL=https://api.fieldkit.org/status
else
	export TERRAFORM_ENV=~/dev-ops/dev.json
	export POLL_URL=https://api.fkdev.org/status
fi

# Warning: If you enable set -x then you will leak database passwords.
set -e

pushd ~/dev-ops

pushd deployer

cargo build --release -j 1

# Warning: If you enable set -x then you will leak database passwords.
MIGRATE_DATABASE_URL=`jq -r .database_url.value $TERRAFORM_ENV` MIGRATE_PATH=$PRIMARY_MIGRATIONS_PATH ~/dev-ops/deploy/migrate migrate
MIGRATE_DATABASE_URL=`jq -r .timescaledb_url.value $TERRAFORM_ENV` MIGRATE_PATH=$TSDB_MIGRATIONS_PATH ~/dev-ops/deploy/migrate migrate

cargo run --release -j 1 deploy \
	--cert $CERT \
	--terraform $TERRAFORM_ENV \
	--archive $ARCHIVE \
	--poll $POLL_URL

popd

popd

echo done
