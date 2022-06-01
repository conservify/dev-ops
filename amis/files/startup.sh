#!/bin/bash

set -xe

source /etc/user_data.env

mkdir -p /tmp/incoming-stacks
mkdir -p /tmp/downloading-stacks

mkdir -p /svr0 /svr1 /svr2 /svr3 /svr4
if [ -e /dev/xvdh ]; then
    mkfs.ext4 /dev/xvdh
    mount /dev/xvdh /svr0
fi

pushd /tmp/downloading-stacks
/var/lib/conservify/startup.py --urls $APPLICATION_STACKS
mv * /tmp/incoming-stacks
popd

systemctl start conservify.service
systemctl start conservify.timer
