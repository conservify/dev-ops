FROM hashicorp/packer

RUN packer plugins install github.com/hashicorp/amazon

WORKDIR /work

COPY bare.json /work/bare.json
COPY stacked.json /work/stacked.json
COPY files build/*.tar* /work/files/
