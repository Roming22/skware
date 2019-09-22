#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`

usage(){
	MODULES_DIR=`cd $SCRIPT_DIR/../../modules; pwd`
	echo "
Options:
  -b,--background run the container in the background
  -h,--help       show this message
  -v,--verbose    increase verbose level

Modules:
`for C in $(find $MODULES_DIR -mindepth 1 -maxdepth 1 -type d -o -type l | sort); do echo "  $(basename $C)"; done`
"
}

init(){
    BIN_DIR=`dirname $SCRIPT_DIR`
    TOOLS_DIR=`cd $SCRIPT_DIR/../.tools; pwd`
}

parse_args(){
    while [[ "$#" -gt 0 ]]; do
        case $1 in
			-b|--background) BACKGROUND="true";;
            -h|--help) usage; exit 0;;
            -v) set -x; VERBOSE="-v" ;;
            *) MODULE_DIR=`$TOOLS_DIR/module_dir.sh $1`;;
        esac
        shift
    done

    [[ -z "$MODULE_DIR" ]] && echo "Specify the path of the module" && exit 1
    MODULE_NAME=`basename $MODULE_DIR`
}

run(){
	source $MODULE_DIR/etc/service.cfg

	[[ `docker images $MODULE_NAME:latest | wc -l` = "1" ]] && $BIN_DIR/build/run.sh $VERBOSE $MODULE_DIR
	$BIN_DIR/stop/run.sh $VERBOSE $MODULE_DIR

	echo "##################################################"
	echo "[$MODULE_NAME] Starting"

	# Make sure to start the containers on a segregated network
	DOCKER_NETWORK=${DOCKER_NETWORK:-$MODULE_NAME}
	IMAGE="skwr/`basename $(cd $MODULE_DIR; pwd)`"
	docker network inspect $DOCKER_NETWORK >/dev/null 2>&1 || docker network create $DOCKER_NETWORK
	trap signal_handler INT
	DOCKER_OPTIONS="$DOCKER_OPTIONS --env TZ=`ls -la /etc/localtime | sed 's:.*zoneinfo/::'` "
	if [ "find $MODULE_DIR/etc -name \*.env | wc -l" != 0 ]; then
		DOCKER_OPTIONS="$DOCKER_OPTIONS `find $MODULE_DIR/etc -name \*.env | sed "s:^ *:--env-file :" | tr '\n' ' '`"
	fi
	DOCKER_OPTIONS="$DOCKER_OPTIONS --hostname $MODULE_NAME "
	DOCKER_OPTIONS="$DOCKER_OPTIONS --name $MODULE_NAME "
	DOCKER_OPTIONS="$DOCKER_OPTIONS --network $DOCKER_NETWORK "
	if [ -e "$MODULE_DIR/volumes/config" ]; then
		DOCKER_OPTIONS="$DOCKER_OPTIONS `cat "$MODULE_DIR/volumes/config" | sed "s:^ *:--volume $MODULE_DIR/volumes/:" | tr '\n' ' '`"
	fi
	CMD="docker run --rm $DOCKER_OPTIONS $IMAGE"
	if [[ "$BACKGROUND" == "true" ]]; then
		$CMD &
		while [[ -z "$FAIL" ]]; do
			sleep 15
			docker ps | grep -q $MODULE_NAME || FAIL="true"
		done
	else
		$CMD
	fi
	echo "[$MODULE_NAME] Stopped"
}

signal_handler(){
	echo
	docker stop $MODULE_NAME >/dev/null
}

init
parse_args $*
run
