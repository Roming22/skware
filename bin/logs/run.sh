#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`

usage(){
	MODULES_DIR=`cd $SCRIPT_DIR/../../modules; pwd`
	echo "
Options:
  -h,--help       show this message
  -v,--verbose    increase verbose level

Modules:
`(docker ps --format "{{.Names}}@{{.Image}}" | grep "@skwr/" | cut -d@ -f1; systemctl | grep skwr_ | sed 's:.*skwr_\([^.]*\).*:\1:') | sort -u | sed 's:^:  :'`
"
}

init(){
    BIN_DIR=`dirname $SCRIPT_DIR`
    TOOLS_DIR=`cd $SCRIPT_DIR/../.tools; pwd`
}

parse_args(){
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -h|--help) usage; exit 0 ;;
            -v) set -x; VERBOSE="-v" ;;
            selfupdate) MODULE_DIR="$1" ;;
            *) MODULE_DIR=`$TOOLS_DIR/module_dir.sh $1` ;;
        esac
        shift
    done

    [[ -z "$MODULE_DIR" ]] && echo "Specify the path of the module" && exit 1
    MODULE_NAME=`basename $MODULE_DIR`
}

run(){
	source $MODULE_DIR/etc/service.cfg

	echo "##################################################"
	echo "[$MODULE_NAME] Streaming logs"

	case $MODULE_NAME in
		selfupdate) journalctl -fu skwr_${MODULE_NAME}.service ;;
		*) docker logs -tf $MODULE_NAME ;;
	esac
}

init
parse_args $*
run
