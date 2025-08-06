FROM hashicorp/packer

RUN packer plugins install github.com/hashicorp/amazon

WORKDIR /work

COPY bare.json /work/bare.json
COPY postgres.json /work/postgres.json
COPY files /work/files/
