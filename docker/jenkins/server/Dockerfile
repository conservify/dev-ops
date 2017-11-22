FROM jenkins/jenkins:lts
USER root
RUN dpkg --add-architecture i386 && apt-get update && apt-get install -yy libc6:i386 build-essential
WORKDIR /tmp
RUN wget https://storage.googleapis.com/golang/go1.9.1.linux-amd64.tar.gz && tar -C /usr/local -xzf go1.9.1.linux-amd64.tar.gz
RUN wget https://nodejs.org/dist/v6.11.4/node-v6.11.4-linux-x64.tar.xz && tar -C /usr/local -xf node-v6.11.4-linux-x64.tar.xz && mv /usr/local/node-* /usr/local/node
RUN wget https://download.docker.com/linux/static/stable/x86_64/docker-17.09.0-ce.tgz && tar -C /usr/local -xf docker-17.09.0-ce.tgz
USER jenkins
