#!/bin/bash
SCRIPT_DIR=`cd $(dirname $(readlink -f $0)); pwd`

usage(){
echo "
Options:
  -h,--help       show this message
  -v,--verbose    increase verbose level

Commands:
`for C in $(find $SCRIPT_DIR -maxdepth 2 -name run.sh -exec dirname {} \; | sort); do echo "  $(basename $C)"; done`
"
}

init(){
  SCRIPT_DIR=`cd $(dirname $(readlink -f $0)); pwd`
  MODULE_DIR="$PWD"
  while [[ ! -e "$MODULE_DIR/image" && ! -e "$MODULE_DIR/etc" ]]; do
    MODULE_DIR=`cd $MODULE_DIR/..; pwd`
    if [[ "$MODULE_DIR" = "/" ]]; then
      unset MODULE_DIR
      break
    fi
  done
}

parse_args(){
  while [[ $# -gt 0 ]]; do
    ARG=$1; shift;
    case $ARG in
      -h|--help) usage; exit 0 ;;
      -v|--verbose) set -x; VERBOSE="-v" ;;
      *) COMMAND="$SCRIPT_DIR/$ARG/run.sh $VERBOSE $*"; break ;;
    esac
  done
}

init
parse_args $*
$COMMAND

