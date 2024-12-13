#!/bin/bash

set -xe

docker-compose start logs
docker-compose start logs-elasticsearch
docker-compose start logs-mongo
