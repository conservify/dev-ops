#!/bin/bash

TEMPLATE=$1

if [ -z $TEMPLATE ]; then
	TEMPLATE=bare.json
fi

docker build --rm -t conservify/build-ami .

if [ -f aws.env ]; then
	source aws.env

	docker run --rm \
		   -e AWS_ACCESS_KEY=$AWS_ACCESS_KEY \
		   -e AWS_SECRET_KEY=$AWS_SECRET_KEY \
		   conservify/build-ami build $TEMPLATE

else

	docker run --rm conservify/build-ami build $TEMPLATE

fi
