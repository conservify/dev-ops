FROM ubuntu:22.04

RUN apt-get update && apt-get install certbot openssh-client rsync -y

ENTRYPOINT [ "/usr/bin/certbot" ]