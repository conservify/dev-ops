FROM jenkins/jenkins:lts
USER root
RUN dpkg --add-architecture i386 && apt-get update && apt-get install -yy libc6:i386 build-essential zlib1g zlib1g:i386 python-pip
RUN pip install virtualenv
WORKDIR /tmp
RUN wget https://dl.google.com/go/go1.10.3.linux-amd64.tar.gz && tar -C /usr/local -xzf go1.10.3.linux-amd64.tar.gz
RUN wget https://nodejs.org/dist/v8.12.0/node-v8.12.0-linux-x64.tar.xz && tar -C /usr/local -xf node-v8.12.0-linux-x64.tar.xz && mv /usr/local/node-* /usr/local/node
RUN wget https://download.docker.com/linux/static/stable/x86_64/docker-17.09.0-ce.tgz && tar -C /usr/local -xf docker-17.09.0-ce.tgz
USER jenkins
