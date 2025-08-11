#!/bin/bash

set -xe

mkdir -p /svr0 /svr1 /svr2 /svr3 /svr4

if [ -e /dev/xvdh ]; then
    if mount /dev/xvdh /svr0; then
        echo mounted existing /dev/xvdh on /svr0
    else
        mkfs.ext4 /dev/xvdh
        mount /dev/xvdh /svr0

	if [ -d /var/lib/postgresql/data ]; then
		mkdir -p /svr0/postgres
		mv /var/lib/postgresql/data /svr0/postgres
		ln -s /svr0/postgres/data /var/lib/postgresql/data
	fi
    fi
fi

if [ -e /dev/nvme1n1p1 ]; then
    if mount /dev/nvme1n1p1 /svr0; then
        echo mounted existing /dev/nvme1n1p1 on /svr0
    else
        mkfs.ext4 /dev/nvme1n1p1
        mount /dev/nvme1n1p1 /svr0

	if [ -d /var/lib/postgresql/data ]; then
		mkdir -p /svr0/postgres
		mv /var/lib/postgresql/data /svr0/postgres
		ln -s /svr0/postgres/data /var/lib/postgresql/data
	fi
    fi
fi

source /etc/user_data.env

mkdir -p /tmp/incoming-stacks
mkdir -p /tmp/downloading-stacks

pushd /tmp/downloading-stacks
/var/lib/conservify/startup.py --urls $APPLICATION_STACKS
mv * /tmp/incoming-stacks
popd

systemctl enable conservify.service
systemctl enable conservify.timer

systemctl start conservify.service
systemctl start conservify.timer
