#!/bin/bash

set -xe

whoami

# See if we have been created with a mapped block device for extra space.
sudo mkdir -p /svr0
if [ -e /dev/xvdd ]; then
	sudo mkfs.ext4 /dev/xvdd
	sudo mount /dev/xvdd /svr0
fi
if [ -e /dev/nvme1n1 ]; then
	sudo mkfs.ext4 /dev/nvme1n1
	sudo mount /dev/nvme1n1 /svr0
fi
sudo mkdir -p /svr0/workspace
sudo mkdir -p /svr0/docker

# When docker installs, it'll find this and end up on extra space.
sudo mkdir -p /var/jenkins_home
sudo ln -sf /svr0/workspace /var/jenkins_home/workspace
sudo mkdir -p /etc/docker
echo '{"data-root": "/svr0/docker"}' > /etc/docker/daemon.json

# Annoying, fix needrestart being interactive by default. May eventually want
# to just use the ENV variable approach. Though, these machines will never use
# anything else.
export NEEDRESTART_SUSPEND=1 

sed -i "/#\$nrconf{restart} = 'i';/s/.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf

# Start installing packages
sudo apt-get update -y
sudo apt-get update -y
sudo apt-get install -qy \
	 apt-transport-https ca-certificates software-properties-common build-essential python3-pip python3-venv python-is-python3 zip ripgrep \
	 openjdk-11-jdk-headless \
	 wget unzip jq curl htop tig valgrind

# Python stuffs.
sudo which pip3
sudo which python3

sudo pip3 install --upgrade pip
sudo pip3 install virtualenv

# This is necessary to run android-sdk's aapt.
sudo apt-get install -qy lib32stdc++6 lib32z1

# Docker
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo mkdir -m 0755 -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo Added repository.

sudo apt-get update

if sudo apt-get install -y -q docker-ce; then
	echo "docker installed"
else
	echo "docker install failed"
	sudo systemctl status docker || true
	sudo journalctl -xe || true
	echo "failing"
	exit 2
fi

# Build tools

wget https://golang.org/dl/go1.19.1.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.19.1.linux-amd64.tar.gz

wget https://nodejs.org/dist/v16.13.2/node-v16.13.2-linux-x64.tar.xz
sudo tar -C /usr/local -xf node-v16.13.2-linux-x64.tar.xz
sudo mv /usr/local/node-* /usr/local/node

wget https://download.docker.com/linux/static/stable/x86_64/docker-17.09.0-ce.tgz
sudo tar -C /usr/local -xf docker-17.09.0-ce.tgz

wget https://github.com/Kitware/CMake/releases/download/v3.19.7/cmake-3.19.7-Linux-x86_64.tar.gz
sudo tar -C /usr/local -xf cmake-3.19.7-Linux-x86_64.tar.gz
sudo mv /usr/local/cmake-* /usr/local/cmake

sudo ln -sf /usr/local/cmake/bin/cmake /usr/local/bin/cmake
sudo ln -sf /usr/local/go/bin/go /usr/local/bin/go
sudo ln -sf /usr/local/node/bin/node /usr/local/bin/node
sudo ln -sf /usr/local/node/bin/npm /usr/local/bin/npm

sudo npm install -g yarn

sudo ln -sf /usr/local/node/bin/yarn /usr/local/bin/yarn

for a in /usr/local/docker/*; do
    echo $a
    n=`basename $a`
    # sudo ln -sf $a /usr/local/bin/$n
done

wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.10.3-stable.tar.xz
sudo tar -C /usr/local -xf flutter_linux_3.10.3-stable.tar.xz

ls -alh /usr/local/flutter

# Cleanup
rm -f *.tar.* *.tgz

# Permissions. We're run from the cloud initialize so that jenkins
# agent starts with the correct group permissions. Otherwise if we're
# run from jenkins this never gets inherited.
sudo usermod -aG docker ubuntu

sudo mkdir /svr0/home
sudo mv /home/ubuntu /svr0/home
sudo ln -sf /svr0/home/ubuntu /home/ubuntu
sudo chown -R ubuntu. /var/jenkins_home
sudo chown -R ubuntu. /svr0/workspace

# System settings and some diagnostics.

echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p

cat /etc/docker/daemon.json

# Ideally the group would handle this for us but I can't seem to get
# the ssh process that Jenkins starts to inherit the permissions
# because of various races with the startup scripts.
sudo chmod 777 /var/run/docker.sock

sudo rm -rf ~/.npm

sudo whoami
sudo id
id
env

# HUP java agent if it's running to get new permissions.
# sudo pkill java

echo done!
