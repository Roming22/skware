#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`

usage(){
	echo "
Options:
  -h,--help       show this message
  -v,--verbose    increase verbose level

Modules:
`systemctl | egrep "^ *skwr-" | sed 's:^ *skwr-\(.*\).service .*:\1:'`
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
    [[ "${MODULE_NAME:0:4}" = "skwr" ]] && SERVICE_NAME="$MODULE_NAME" || SERVICE_NAME="skwr-$MODULE_NAME"
}

run(){
	set -e

	echo "[$MODULE_NAME] Uninstalling"
	source $MODULE_DIR/etc/service.cfg

	# Uninstall services
	echo "[$MODULE_NAME] Deactivating"
	for SERVICE in $SERVICE_NAME.service $SERVICE_NAME-selfupdate.service; do
		if [[ -e "/etc/systemd/system/$SERVICE" ]]; then
			sudo systemctl stop $SERVICE
			sudo systemctl disable $SERVICE 2> /dev/null
			sudo rm "/etc/systemd/system/$SERVICE"
		fi
	done

	# Clean the system
	echo "$MODULE_NAME: Cleaning configuration"
	sudo systemctl daemon-reload
	IMAGE_ID=`docker images -q $MODULE_NAME`
	[[ ! -z "$IMAGE_ID" ]] && docker rmi $IMAGE_ID

	echo "[$MODULE_NAME] Uninstalled"
}

init
parse_args $*
run
