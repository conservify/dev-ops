#!/bin/bash

#!/bin/bash

cp mappings.json /svr0/graylog/data/elasticsearch/

docker exec docker_logs-elasticsearch_1 pwd
docker exec docker_logs-elasticsearch_1 ls -alh data
docker exec docker_logs-elasticsearch_1 curl -X PUT -d @'data/mappings.json' -H 'Content-Type: application/json' 'http://127.0.0.1:9200/_template/graylog-custom-mapping?pretty'

