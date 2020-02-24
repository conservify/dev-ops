#!/bin/bash

source /etc/lsb-release

set -xe

# configure extra package repositories

curl -fsSL https://repos.influxdata.com/influxdb.key | apt-key add -

echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | tee /etc/apt/sources.list.d/influxdb.list

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

echo "deb https://download.docker.com/linux/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | tee /etc/apt/sources.list.d/docker.list

# install log forwarding stuff

curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.6.0-amd64.deb

dpkg -i filebeat-7.6.0-amd64.deb && rm *.deb

systemctl enable filebeat

# update packages and install the things we need

apt-get update

apt-get install -y \
		tmux vim git jq \
		docker-ce docker-ce-cli containerd.io \
		telegraf

# add ubuntu to docker group

usermod -aG docker ubuntu

# install docker-compose

curl -L "https://github.com/docker/compose/releases/download/1.25.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
docker-compose --version

# enable telegraf

systemctl enable telegraf

systemctl disable snap.amazon-ssm-agent.amazon-ssm-agent
