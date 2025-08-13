#!/bin/bash

source /etc/user_data.env

set -xe

DEVICES="/dev/xvdh /dev/nvme1n1"

for device in $DEVICES; do
	echo $device: checking
	if [ -e $device ]; then
		mkdir -p /svr0

		if mount $device /svr0; then
			echo $device: mounted existing on /svr0
		else
			echo $device: formatting and mounting new disk

			mkfs.ext4 $device

			echo $device: adding /etc/fstab row
			UUID=$(blkid -o value -s UUID $device)
			cat <<EOF >> /etc/fstab
UUID=$UUID	/svr0	ext4	defaults	0 0
EOF

			echo $device: mounting
			mount /svr0

			if [ -d /var/lib/postgresql/17/main ]; then
				echo $device: rehoming /var/lib/postgresql/17/main to /svr0/postgres
				echo $device: stopping postgresql
				systemctl stop postgresql
				echo $device: moving /var/lib/postgresql/17/main
				mkdir -p /svr0/postgres
				mv /var/lib/postgresql/17/main /svr0/postgres
				ln -s /svr0/postgres/main /var/lib/postgresql/17/main
				chown postgres: /var/lib/postgresql/17/main
				echo $device: starting postgresql
				systemctl start postgresql
			fi
		fi

		break
	fi
done

# If we have a PostgreSQL server set the password.
if [ -x /usr/lib/postgresql/*/bin/postgres ]; then
	su - postgres -c "psql -c \"ALTER USER postgres with password '$FIELDKIT_POSTGRES_DB_PASSWORD'\""
fi

# Large file of nothing we can delete if disk fills up.
if [ ! -f /empty.data ]; then
	echo creating empty.data for full disk recovery
	dd if=/dev/zero of=/empty.data count=1024 bs=10M
fi

# Download startup stacks and queue them up for loading.
mkdir -p /tmp/incoming-stacks
mkdir -p /tmp/downloading-stacks
pushd /tmp/downloading-stacks
/var/lib/conservify/startup.py --urls $APPLICATION_STACKS
if test -n "$(shopt -s nullglob; echo *)"; then
	echo moving startup stacks
	mv * /tmp/incoming-stacks
else
	echo no startup stacks found
fi
popd

# eof
