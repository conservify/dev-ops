#!/bin/bash

set -e

if [ -z $1 ]; then
	WATCHING=/tmp
else
	WATCHING=$1
fi

for archive in `find ${WATCHING} -name "*.tar"`; do
	name=`basename $archive .tar`
	work=/tmp/${name}

	rm -rf ${work}
	mkdir -p ${work}

	tar xf ${archive} -C ${work}

	pushd ${work}

	for image in *.di; do
		docker load < ${image} && rm ${image}
	done

	ls -alh

	mkdir -p /etc/docker/compose/${name}

	cp * /etc/docker/compose/${name}
	cp /etc/user_data.env /etc/docker/compose/99_user_data.env

	popd

	rm -rf ${work} ${archive}

	systemctl enable docker-compose@${name}

	systemctl restart docker-compose@${name}
done
