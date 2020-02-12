#!/bin/bash

set -e

if [ -f /tmp/stack.tar ]; then
	rm -rf /tmp/images
	mkdir -p /tmp/images
	pushd /tmp/images
	tar xf /tmp/stack.tar
	for image in *.di; do
		docker load < ${image}
	done
	popd
fi
