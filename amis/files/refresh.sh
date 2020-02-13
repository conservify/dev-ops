#!/bin/bash

set -e

if [ -z $1 ]; then
	WATCHING=/tmp/incoming-stacks
else
	WATCHING=$1
fi

for archive in `find ${WATCHING} -name "*-stack.tar*"`; do
	name=`basename $archive .tar`
	work=/tmp/${name}
	compose_dir=/etc/docker/compose/${name}

	rm -rf ${work}
	mkdir -p ${work}

	tar xf ${archive} -C ${work}

	pushd ${work}

	for image in *.di; do
		docker load < ${image} && rm ${image}
	done

	ls -alh

	mkdir -p ${compose_dir}

	cp * ${compose_dir}
	cp /etc/user_data.env ${compose_dir}/99_user_data.env

	popd

	rm -rf ${work} ${archive}

	systemctl enable docker-compose@${name}

	systemctl restart docker-compose@${name}
done
