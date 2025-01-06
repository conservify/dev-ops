#!/bin/bash

docker exec docker_logs-elasticsearch_1 curl -XPOST -H "Content-Type: application/json" http://localhost:9200/_cluster/reroute?retry_failed
