#!/bin/sh

set -xe

WORK=$(mktemp -d "${TMPDIR:-/tmp/}$(basename $0).XXXXXXXXXXXX")
CHALLENGES=$WORK/acme-challenge

mkdir -p $CHALLENGES

echo $CERTBOT_VALIDATION > $CHALLENGES/$CERTBOT_TOKEN

ls -lh $CHALLENGES

scp -r $CHALLENGES $WEB_ROOT_HOST:/app/.well-known/

rm -rf $WORK

