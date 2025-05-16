#!/bin/bash

source /etc/lsb-release

set -xe

# configure influxdata apt for telegraf, copied literally from documentation

curl --silent --location -O \
https://repos.influxdata.com/influxdata-archive.key \
&& echo "943666881a1b8d9b849b74caebf02d3465d6beb716510d86a39f6c8e8dac7515  influxdata-archive.key" \
| sha256sum -c - && cat influxdata-archive.key \
| gpg --dearmor \
| sudo tee /etc/apt/trusted.gpg.d/influxdata-archive.gpg > /dev/null \
&& echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive.gpg] https://repos.influxdata.com/debian stable main' \
| sudo tee /etc/apt/sources.list.d/influxdata.list

# configure docker apt

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

echo "deb https://download.docker.com/linux/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | tee /etc/apt/sources.list.d/docker.list

# install useful packages

apt-get update

apt-get install -y \
		tmux vim git ripgrep htop jq \
		docker-ce docker-ce-cli containerd.io \
		telegraf

# install log forwarding tooling

curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.6.0-amd64.deb
dpkg -i filebeat-7.6.0-amd64.deb && rm *.deb
filebeat modules enable system
systemctl enable filebeat

# add ubuntu to docker group

usermod -aG docker ubuntu

# install docker-compose

curl -L "https://github.com/docker/compose/releases/download/1.25.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
docker-compose --version

# enable telegraf

systemctl enable telegraf

# cleanup

systemctl disable snap.amazon-ssm-agent.amazon-ssm-agent

if [ -d ~ubuntu/.config ]; then
	chown -R ubuntu: ~ubuntu/.config
fi
