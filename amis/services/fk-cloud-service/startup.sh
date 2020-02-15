#!/bin/sh

/app/server &

envoy -c /etc/service-envoy.yaml --service-cluster fk-cloud
