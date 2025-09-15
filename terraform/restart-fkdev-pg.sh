#!/bin/bash

STAMP=`date "+%Y%m%d-%H%M%S"`
CONFIG_FILE=fk/terraform.tfvars.json
BACKUP_FILE=${CONFIG_FILE}-${STAMP}

KIND=workspace_pg_servers
ENV=dev
COLOR=pg-purple
APPLY=0

usage() {
  echo "Usage: restart-fkdev-pg.sh --apply"

  exit 2
}

PARSED_ARGUMENTS=$(getopt -o '' --long apply -- "$@")
VALID_ARGUMENTS=$?
if [ "$VALID_ARGUMENTS" != "0" ]; then
	  usage
fi

eval set -- "$PARSED_ARGUMENTS"
while :
do
  case "$1" in
    --apply) APPLY=1    ; shift   ;;
    --) shift; break ;;
    *) echo "Unexpected option: $1 - how did you get here?"
       usage ;;
  esac
done

ENABLED_PATH=".${KIND}.${ENV}.\"${COLOR}\".enabled"
BEFORE=$(jq ${ENABLED_PATH} ${CONFIG_FILE})

case $BEFORE in
    "true") echo "OK ${ENABLED_PATH} = ${BEFORE}" ;;
    *) echo "FAIL ${ENABLED_PATH} is invalid (${BEFORE})"; exit 2 ;;
esac

cp ${CONFIG_FILE} ${BACKUP_FILE}

jq "${ENABLED_PATH} = \"false\"" ${BACKUP_FILE} > ${CONFIG_FILE}

diff ${BACKUP_FILE} ${CONFIG_FILE} || true

if [ $APPLY -eq 1 ]; then
	make ${ENV} plan apply
else
	make ${ENV} plan
fi

jq "${ENABLED_PATH} = ${BEFORE}" ${BACKUP_FILE} > ${CONFIG_FILE}

diff ${BACKUP_FILE} ${CONFIG_FILE} || true

if [ $APPLY -eq 1 ]; then
	make ${ENV} plan apply
else
	make ${ENV} plan
fi
