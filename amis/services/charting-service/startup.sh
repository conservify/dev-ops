#!/bin/bash

echo starting cloud service: $@

EXEC=$1

if [ -f /etc/static.env ]; then
	echo found /etc/static.env
	source /etc/static.env
fi

pwd
ls -alh
env

ts-node server.ts
