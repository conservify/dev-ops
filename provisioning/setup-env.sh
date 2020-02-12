#!/bin/bash

pushd ../terraform/fk
export ENV_DB_URL=`terraform output database_url`
export APP_SERVER_ADDRESS=`terraform output app_server_address`
export FK_CLOUD_ROOT=~/fieldkit/cloud
popd
