#!/bin/sh

set -xe

WORK=$(mktemp -d "${TMPDIR:-/tmp/}$(basename $0).XXXXXXXXXXXX")
CHALLENGES=$WORK/acme-challenge

mkdir -p $CHALLENGES

echo $CERTBOT_VALIDATION > $CHALLENGES/$CERTBOT_TOKEN

ls -lh $CHALLENGES

for HOST in $WEB_ROOT_HOSTS; do
	echo $HOST

    scp -o StrictHostKeyChecking=no -J code -r $CHALLENGES ubuntu@$HOST:/app/.well-known/
done

rm -rf $WORK

