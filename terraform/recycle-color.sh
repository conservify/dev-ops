#!/bin/bash

STAMP=`date "+%Y%m%d-%H%M%S"`
CONFIG_FILE=fk/terraform.tfvars.json
BACKUP_FILE=${CONFIG_FILE}-${STAMP}

KIND=unset
COLOR=unset
ENV=dev
APPLY=0

usage() {
  echo "Usage: recycle-colors.sh --env <dev|prod> --color <COLOR>  --kind (workspace_postgres_servers|workspace_servers) --apply"

  exit 2
}

PARSED_ARGUMENTS=$(getopt -o '' --long env:,color:,kind:,apply -- "$@")
VALID_ARGUMENTS=$?
if [ "$VALID_ARGUMENTS" != "0" ]; then
	  usage
fi

eval set -- "$PARSED_ARGUMENTS"
while :
do
  case "$1" in
    --env)   ENV="$2"   ; shift 2 ;;
    --color) COLOR="$2" ; shift 2 ;;
    --kind)  KIND="$2"  ; shift 2 ;;
    --apply) APPLY=1    ; shift   ;;
    --) shift; break ;;
    *) echo "Unexpected option: $1 - how did you get here?"
       usage ;;
  esac
done

NUMBER_PATH=".${KIND}.${ENV}.${COLOR}.number"
BEFORE=`jq ${NUMBER_PATH} < ${CONFIG_FILE}`

case $BEFORE in
    ''|*[!0-9]*) echo "FAIL ${NUMBER_PATH} is invalid"; exit 2 ;;
    *) echo "OK ${NUMBER_PATH} = ${BEFORE}" ;;
esac

cp ${CONFIG_FILE} ${BACKUP_FILE}

jq "${NUMBER_PATH} = 0" < ${BACKUP_FILE} > ${CONFIG_FILE}

diff ${BACKUP_FILE} ${CONFIG_FILE} || true

if [ $APPLY -eq 1 ]; then
	make ${ENV} plan apply
else
	make ${ENV} plan
fi

jq "${NUMBER_PATH} = ${BEFORE}" < ${BACKUP_FILE} > ${CONFIG_FILE}

diff ${BACKUP_FILE} ${CONFIG_FILE} || true

if [ $APPLY -eq 1 ]; then
	make ${ENV} plan apply
else
	make ${ENV} plan
fi
