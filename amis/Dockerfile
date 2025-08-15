FROM hashicorp/packer

RUN packer plugins install github.com/hashicorp/amazon

WORKDIR /work

COPY *.json /work/
COPY files /work/files/
