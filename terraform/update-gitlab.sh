#!/bin/bash

SECURE_CONFIG=`pwd`/fk/terraform.tfvars.json

pushd ~/conservify/laborator
cargo run -- secret --project 48313780 --file $SECURE_CONFIG --key terraform.json
popd
