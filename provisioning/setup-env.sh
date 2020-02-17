#!/bin/bash

pushd ../terraform/fk
source aws.env
export ENV_DB_URL=`terraform output database_url`
export FK_CLOUD_ROOT=~/fieldkit/cloud
popd
