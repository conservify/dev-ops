set -xe

sudo apt-get update
sudo apt-get install -qy openjdk-8-jdk-headless wget apt-transport-https ca-certificates curl software-properties-common unzip

# This is necessary to run android-sdk's aapt.
sudo apt-get install -qy lib32stdc++6 lib32z1

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get update

sudo apt-get install -qy docker-ce

wget https://dl.google.com/go/go1.10.3.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.10.3.linux-amd64.tar.gz

wget https://nodejs.org/dist/v6.11.4/node-v6.11.4-linux-x64.tar.xz
sudo tar -C /usr/local -xf node-v6.11.4-linux-x64.tar.xz
sudo mv /usr/local/node-* /usr/local/node

wget https://download.docker.com/linux/static/stable/x86_64/docker-17.09.0-ce.tgz
sudo tar -C /usr/local -xf docker-17.09.0-ce.tgz

sudo ln -sf /usr/local/go/bin/go /usr/local/bin/go
sudo ln -sf /usr/local/node/bin/node /usr/local/bin/node
sudo ln -sf /usr/local/node/bin/npm /usr/local/bin/npm
for a in /usr/local/docker/*; do
    echo $a
    n=`basename $a`
    # sudo ln -sf $a /usr/local/bin/$n
done

sudo usermod -aG docker ubuntu

sudo mkdir /var/jenkins_home
sudo chown -R ubuntu. /var/jenkins_home

echo Done!
