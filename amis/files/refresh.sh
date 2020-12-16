#!/bin/bash

if [ -z $HOME ]; then
	HOME="/tmp"
fi

set -e

if [ -z $1 ]; then
	WATCHING=/tmp/incoming-stacks
else
	WATCHING=$1
fi

mkdir -p ${WATCHING}

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
		image_name=`basename ${image} .di`
		echo loading ${image}

		# So we load the image here and then parse the image name and
		# tag from the output of the load call, here's an example of
		# the output we'll get:
		# Loaded image: conservify/fk-cloud-proxy:20200213-225502
		loaded=`docker load -i ${image} | sed -n 's/^Loaded image: \([0-9a-f]*\)/\1/p'`
		service=`echo ${loaded} | awk -F':' '{print $1}'`
		tag=`echo ${loaded} | awk -F':' '{print $2}'`

		# Remove the old 'active' tag and then tag this new one.
		echo loaded ${loaded}...
		docker rmi ${service}:active || true
		docker tag ${loaded} ${service}:active

		rm ${image}
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
