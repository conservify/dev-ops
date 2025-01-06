#!/bin/bash

docker exec docker_logs-elasticsearch_1 curl -XPUT -H "Content-Type: application/json" http://localhost:9200/_cluster/settings -d '{"persistent": { "cluster.routing.allocation.enable": null }}'
