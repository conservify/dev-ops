#!/bin/bash

source .env

set -xe

for ip in $SERVERS; do
	ssh ubuntu@$ip sudo systemctl restart docker-compose@portal-stack.service
done
