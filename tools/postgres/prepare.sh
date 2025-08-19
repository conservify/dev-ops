#!/bin/bash

set -xe

chmod 600 ~/.pgpass
sudo mkdir -p /svr0/migration
sudo chown -R ubuntu: /svr0/migration
