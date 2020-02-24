#!/bin/bash

source /etc/user_data.env

if [ ! -z "$APPLICATION_STACK" ]; then
	mkdir -p /tmp/incoming-stacks
	mkdir -p /tmp/downloading-stacks
	pushd /tmp/downloading-stacks
	wget -q --auth-no-challenge $APPLICATION_STACK
	mv * /tmp/incoming-stacks
	popd
fi
