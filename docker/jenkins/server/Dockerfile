FROM jenkins/jenkins:latest
USER root
RUN dpkg --add-architecture i386 && apt-get update && apt-get install -yy libc6:i386 build-essential zlib1g wget zip zlib1g:i386 binutils-arm-none-eabi rsync jq vim valgrind gdb doxygen python3-pip python3-venv python3-setuptools
WORKDIR /tmp
ADD lief-0.10.0.dev0-py3.6-linux-x86_64.egg /tmp
RUN pip3 install lief
RUN wget https://nodejs.org/dist/v12.18.1/node-v12.18.1-linux-x64.tar.xz && tar -C /usr/local -xf node-v12.18.1-linux-x64.tar.xz && mv /usr/local/node-* /usr/local/node
RUN PATH=$PATH:/usr/local/node/bin npm install -g yarn
RUN wget https://download.docker.com/linux/static/stable/x86_64/docker-17.09.0-ce.tgz && tar -C /usr/local -xf docker-17.09.0-ce.tgz
ENV log4j2.formatMsgNoLookups=True
# USER jenkins
