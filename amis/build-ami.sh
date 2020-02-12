#!/bin/bash

source aws.env

docker build --rm -t conservify/build-ami .

docker run --rm \
	   -e AWS_ACCESS_KEY=$AWS_ACCESS_KEY \
	   -e AWS_SECRET_KEY=$AWS_SECRET_KEY \
	   conservify/build-ami build build.json
