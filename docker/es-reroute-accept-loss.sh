#!/bin/bash

docker exec docker_logs-elasticsearch_1 curl -XPOST -H "Content-Type: application/json" http://localhost:9200/_cluster/reroute?metric=none -d '{ "commands": [ { "allocate_empty_primary": { "index": "graylog_25884", "shard": 1, "node": "sjUvLVZITjyapbP61-4M9w", "accept_data_loss": "true" } } ] }'
