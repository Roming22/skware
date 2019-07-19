#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`

usage(){
	MODULES_DIR=`cd $SCRIPT_DIR/../../modules; pwd`
	echo "
Options:
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
	docker run $DOCKER_OPTIONS --rm --network $DOCKER_NETWORK --name $MODULE_NAME --hostname $MODULE_NAME $IMAGE &
	while [[ -z "$FAIL" ]]; do
		sleep 15
		docker inspect $MODULE_NAME >/dev/null || FAIL="true"
	done
	echo "[$MODULE_NAME] Stopped"
}

signal_handler(){
	echo
	docker stop $MODULE_NAME >/dev/null
}

init
parse_args $*
run
