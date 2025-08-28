#!/bin/bash

PG_VERSION_MAJOR=16

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
		fi

		PG_MAIN=/var/lib/postgresql/$PG_VERSION_MAJOR/main

		if [ -d $PG_MAIN ]; then
			if [ ! -L $PG_MAIN ]; then
				echo $device: rehoming $PG_MAIN to /svr0/postgres

				# Stop the server, since we'll be moving data directories around.
				echo $device: stopping postgresql
				systemctl stop postgresql
				while /bin/true; do
					if [ ! -f $PG_MAIN/postmaster.pid ]; then
						break
					fi
				  sleep 1
				done

				# If no data directory on the volume, create one and move the pristine data directory there.
				if [ ! -d /svr0/postgres ]; then
					echo $device: moving $PG_MAIN
					mkdir -p /svr0/postgres
					mv $PG_MAIN /svr0/postgres
				fi

				# Link to new data directory and start postgres. We refuse to start postgres
				# again if we're in some unanticipated state.
				if [ -d /svr0/postgres/main ]; then
					if [ -d $PG_MAIN ]; then
						echo backup $PG_MAIN 
						mv $PG_MAIN ${PG_MAIN}-backup
					fi
					ln -s /svr0/postgres/main $PG_MAIN
					chown postgres: $PG_MAIN
					echo $device: starting postgresql
					systemctl start postgresql
				fi
			fi
		fi

		break
	fi
done

# If we have a PostgreSQL server set the password.
if [ -x /usr/lib/postgresql/*/bin/postgres ]; then
	while /bin/true; do
		if su - postgres -c "psql -c \"ALTER USER postgres WITH PASSWORD '$FIELDKIT_POSTGRES_DB_PASSWORD'\""; then
			break
		fi
		sleep 1
	done
fi

# This will only do anything if we're restoring from a snapshot.
su - postgres -c "psql -c \"ALTER USER fk WITH PASSWORD '$FIELDKIT_POSTGRES_DB_PASSWORD'\"" || true

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
