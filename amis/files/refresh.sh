#!/bin/bash

set -e

if [ -f /tmp/stack.tar ]; then
	rm -rf /tmp/stack
	mkdir -p /tmp/stack

	pushd /tmp/stack

	tar xf /tmp/stack.tar

	for image in *.di; do
		docker load < ${image} && rm ${image}
	done

	ls -alh

	mkdir -p /etc/docker/compose/stack
	cp *.env .env /etc/docker/compose/stack
	cp docker-compose.yaml /etc/docker/compose/stack

	popd

	rm -rf /tmp/stack*

	systemctl enable docker-compose@stack

	systemctl start docker-compose@stack
fi
