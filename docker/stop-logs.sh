#!/bin/bash

set -xe

docker-compose stop logs
docker-compose stop logs-elasticsearch
docker-compose stop logs-mongo
