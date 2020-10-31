#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`

usage(){
	MODULES_DIR=`cd $SCRIPT_DIR/../../modules; pwd`
	echo "
Options:
  -h,--help       show this message
  -d,--daemon     run the update continuously
  -q,--quiet      minimum amount of logging
  -v,--verbose    increase verbose level

Modules:
`systemctl | egrep "^ *skwr-" | sed 's:^ *skwr-\(.*\).service .*:\1:'`

Commands:
  logs    Display the logs from journalctl
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
			-d|--daemon) DAEMON="true" ;;
			-q|--quiet) QUIET="true" ;;
			-v) set -x; VERBOSE="-v" ;;
			logs) journalctl -qu skwr_selfupdate -n all -f --no-hostname; exit 0;;
			*) MODULE_NAMES="$MODULE_NAMES $1";;
		esac
		shift
	done

	[[ -z "$MODULE_NAMES" ]] && MODULE_NAMES=`systemctl | egrep "^ *skwr-" | sed 's:^ *skwr-\(.*\).service .*:\1:'`
	[[ -z "$MODULE_NAMES" ]] && echo "No module to process" && exit 1
	MODULE_NAMES=("$MODULE_NAMES")
}

run(){
	echo "### RUN as ${USER} ####################################" | cut -b1-50
	echo "Modules: $MODULE_NAMES" | tr '\n' ',' | sed -e 's:,\(.\):, \1:g' -e 's:,$:\n:';
	[[ -n "$DAEMON" ]] && run_daemon || update_images
	exit $?
	echo "Done"
}

run_daemon(){
	while [[ true ]]; do
		# Wait for 10 to 20 minutes before checking for any update
		INTERVAL=$(( 600 + (RANDOM % 600) ))
		echo "### UPDATE at `date --date="$INTERVAL seconds" +'%b %d %H:%M:%S'` ####################"
		sleep $INTERVAL
		update_images
	done
}

update_images(){
	for MODULE_NAME in $MODULE_NAMES; do
		[[ -z "$QUIET" ]] && build_image || build_image >/dev/null
		check_image
		[[ -z "$QUIET" ]] && clean_images || clean_images >/dev/null
	done
}

build_image(){
	MODULE_DIR=`$TOOLS_DIR/module_dir.sh $MODULE_NAME`

	echo "### $MODULE_NAME ####################################" | cut -b1-50
	source $MODULE_DIR/etc/service.cfg
	cd $MODULE_DIR
	git pull
	$BIN_DIR/build/run.sh $PWD
	cd - >/dev/null
}

check_image(){
	IMAGE=skwr/`basename $MODULE_DIR`
	IMAGE_ID=`docker inspect $IMAGE:latest | grep Id | cut -d: -f3`

	# Restart service if a new image was generated
	CONTAINER_ID=`docker ps -q -f name=^/$MODULE_NAME$`
	if [[ -z "$CONTAINER_ID" ]]; then
		echo "[$MODULE_NAME] Not running"
		return
	fi

	CONTAINER_IMAGE_ID=`docker inspect $CONTAINER_ID | grep Image | grep sha256:  | cut -d: -f3`
	if [[ "$IMAGE_ID" != "$CONTAINER_IMAGE_ID" ]]; then
		SERVICE_NAME="skwr-$MODULE_NAME.service"
		echo "[$MODULE_NAME] Update found, restarting $SERVICE_NAME"
		sudo systemctl stop $SERVICE_NAME
		sudo systemctl start $SERVICE_NAME
	else
		echo "[$MODULE_NAME] No update"
	fi
}

clean_images(){
	# Clean-up old images
	docker images | egrep "^$IMAGE " | sort -r | tail -n +5 | awk '{print $3}' | while read IMAGE; do
		docker rmi $IMAGE
	done
}

init
parse_args $*
run
