#!/bin/bash

TEMPLATE=$1

if [ -z $TEMPLATE ]; then
	TEMPLATE=bare.json
fi

if [ -f aws.env ]; then
	source aws.env
fi

if [ ! -z "$AWS_ACCESS_KEY_ID" ]; then
	AWS_ACCESS_KEY="$AWS_ACCESS_KEY_ID"
fi

if [ ! -z "$AWS_SECRET_ACCESS_KEY" ]; then
	AWS_SECRET_KEY="$AWS_SECRET_ACCESS_KEY"
fi

docker build --rm -t conservify/build-ami .

docker run --rm \
	   -e AWS_ACCESS_KEY=$AWS_ACCESS_KEY \
	   -e AWS_SECRET_KEY=$AWS_SECRET_KEY \
	   conservify/build-ami build $TEMPLATE
