#!/bin/bash

echo starting cloud service: $@

EXEC=$1

if [ -f /etc/static.env ]; then
	echo found /etc/static.env
	source /etc/static.env
fi

pushd /app
node_modules/.bin/ts-node server.ts
popd
