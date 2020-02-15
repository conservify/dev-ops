#!/bin/bash

set -e

if [ -z $1 ]; then
	WATCHING=/tmp/incoming-stacks
else
	WATCHING=$1
fi

for archive in `find ${WATCHING} -name "*.tar*"`; do
	name=`basename $archive .tar`
	work=/tmp/${name}

	# Uncompress into a work directory and take a peak.
	rm -rf ${work}
	mkdir -p ${work}
	tar xf ${archive} -C ${work}

	pushd ${work}

	ls -alh

	# No matter which kind of image this is, try and load the docker containers inside.
	for image in *.di; do
		docker load < ${image} && rm ${image}
	done

	# Is this a stack of services in a docker-compose bundle?
	if [ -f docker-compose.yaml ]; then
		compose_dir=/etc/docker/compose/${name}

		mkdir -p ${compose_dir}
		cp * ${compose_dir}
		cp /etc/user_data.env ${compose_dir}/99_user_data.env

		# Start this thing up, ensuring it's setup to run and then hup the services.
		systemctl enable docker-compose@${name}
		systemctl restart docker-compose@${name}
	fi

	popd

	rm -rf ${work} ${archive}
done
