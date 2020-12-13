#!/bin/sh

echo starting cloud service: $@

EXEC=$1

if [ -f /etc/static.env ]; then
	echo found /etc/static.env
	source /etc/static.env
fi

{ $EXEC; } &

{ envoy -c /etc/service-envoy.yaml --service-cluster fk-cloud; } &

wait -n

pkill -P $$
