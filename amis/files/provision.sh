#!/bin/bash

source /etc/lsb-release

set -xe

curl -fsSL https://repos.influxdata.com/influxdb.key | apt-key add -

echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | tee /etc/apt/sources.list.d/influxdb.list

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

echo "deb https://download.docker.com/linux/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | tee /etc/apt/sources.list.d/docker.list

apt-get update

apt-get install -y \
		docker-ce docker-ce-cli containerd.io \
		telegraf

curl -L "https://github.com/docker/compose/releases/download/1.25.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

docker-compose --version

ls -alh

systemctl enable telegraf
systemctl start telegraf
