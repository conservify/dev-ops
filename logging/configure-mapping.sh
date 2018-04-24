#!/bin/bash

# curl -X PUT -d @'graylog-custom-mapping.json' 'http://127.0.0.1:9200/_template/graylog-custom-mapping?pretty'

# curl -X GET 'http://127.0.0.1:9200/graylog_deflector/_mapping?pretty'

docker cp graylog-custom-mapping.json docker_logs-elasticsearch_1:/usr/share/elasticsearch
docker exec docker_logs-elasticsearch_1 curl -X PUT -d @'graylog-custom-mapping.json' 'http://localhost:9200/_template/graylog-custom-mapping?pretty'

docker exec docker_logs-elasticsearch_1 curl -X GET 'http://localhost:9200/_template?pretty'

# docker exec docker_logs-elasticsearch_1 curl -X GET 'http://localhost:9200/graylog_deflector/_mapping?pretty'

