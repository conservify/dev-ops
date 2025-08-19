#!/bin/bash

source .env

set -xe

for ip in $SERVERS; do
	scp ${ip}_user_data.env ubuntu@$ip:user_data.env
	ssh ubuntu@$ip sudo mv user_data.env /etc
done
