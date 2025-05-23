#!/bin/bash

SECURE_CONFIG=`pwd`/build/deploy.json

echo ${SECURE_CONFIG}

make dev env
pushd ~/fk/tools/laborator
cargo run -- secret --project 48313780 --file $SECURE_CONFIG --key dev.json
popd

make prod env
pushd ~/fk/tools/laborator
cargo run -- secret --project 48313780 --file $SECURE_CONFIG --key prod.json
popd
