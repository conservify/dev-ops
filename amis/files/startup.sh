#!/bin/bash

set -xe

source /etc/user_data.env

mkdir -p /tmp/incoming-stacks
mkdir -p /tmp/downloading-stacks

pushd /tmp/downloading-stacks
/var/lib/conservify/startup.py --urls $APPLICATION_STACKS
mv * /tmp/incoming-stacks
popd

systemctl start conservify.service
systemctl start conservify.timer
