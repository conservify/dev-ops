FROM jenkins/jenkins:lts
USER root
RUN dpkg --add-architecture i386 && apt-get update && apt-get install -yy libc6:i386 build-essential zlib1g zlib1g:i386 python3-pip python-pip zip doxygen binutils-arm-none-eabi rsync jq vim
RUN pip install virtualenv
RUN pip3 install virtualenv
WORKDIR /tmp
ADD lief-0.10.0.dev0-py3.6-linux-x86_64.egg /tmp
RUN python3 -m easy_install --no-deps lief-0.10.0.dev0-py3.6-linux-x86_64.egg
RUN wget https://nodejs.org/dist/v12.18.1/node-v12.18.1-linux-x64.tar.xz && tar -C /usr/local -xf node-v12.18.1-linux-x64.tar.xz && mv /usr/local/node-* /usr/local/node
RUN wget https://download.docker.com/linux/static/stable/x86_64/docker-17.09.0-ce.tgz && tar -C /usr/local -xf docker-17.09.0-ce.tgz
USER jenkins
