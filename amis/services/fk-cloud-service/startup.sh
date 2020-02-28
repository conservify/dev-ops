#!/bin/sh

echo starting cloud service: $@

EXEC=$1

if [ -f /etc/static.env ]; then
	echo found /etc/static.env
	source /etc/static.env
fi

if [ -f $EXEC ]; then
	$EXEC &
fi

envoy -c /etc/service-envoy.yaml --service-cluster fk-cloud
