FROM hashicorp/packer

RUN packer plugins install github.com/hashicorp/amazon

WORKDIR /work

COPY bare.json /work/bare.json
COPY files /work/files/
