#!/bin/sh

echo starting cloud service..
echo args: $@

EXEC=$1

if [ -f $EXEC ]; then
	$EXEC &
fi

envoy -c /etc/service-envoy.yaml --service-cluster fk-cloud
