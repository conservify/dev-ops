#!/bin/bash

source .env

set -xe

for ip in $SERVERS; do
	ssh ubuntu@$ip sudo cp /etc/user_data.env ~/
	scp ubuntu@$ip:user_data.env ${ip}_user_data.env
done

