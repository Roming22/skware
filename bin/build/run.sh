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
	DOCKER_DIR="$MODULE_DIR/image"
	TAG="skwr/`basename $(cd $MODULE_DIR; pwd)`"
}

run(){
	echo "[$MODULE_NAME] Building"
	docker build --rm --pull --tag $TAG:build -f $DOCKER_DIR/Dockerfile $DOCKER_DIR || exit 1

	if [[ `docker images -q $TAG:latest` != `docker images -q $TAG:build` ]]; then
		docker tag $TAG:build $TAG:`date +%Y.%m%d.%H%M`
		docker tag $TAG:build $TAG:latest
	fi
	docker rmi $TAG:build >/dev/null
	echo "[$MODULE_NAME] Built"
}

init
parse_args $*
run
