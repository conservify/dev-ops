#!/bin/bash

pushd ../terraform
export ENV_DB_URL=`terraform output db_url`
export APP_SERVER_ADDRESS=`terraform output app_server_address`
export FK_CLOUD_ROOT=~/fieldkit/cloud
popd
