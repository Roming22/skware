#!/bin/bash

while [[ "$#" -gt 0 ]]; do
	case $1 in
		-v) set -x ;;
		*) MODULE_DIR=`cd $1; pwd`;;
	esac
	shift
done

[[ -z "$MODULE_DIR" ]] && echo "Specify the path of the module" && exit 1
MODULE_NAME=`basename $MODULE_DIR`

DOCKER_DIR="$MODULE_DIR/docker"
TAG=`basename $MODULE_DIR`

echo "$MODULE_NAME: Building"
ARCHITECTURE=`lscpu | head -1 | awk '{print $2}'`
case $ARCHITECTURE in
	armv7*) ARCHITECTURE="armv7" ;;
esac

if [[ ! `docker build --rm --pull --tag $TAG:build -f $MODULE_DIR/docker/Dockerfile.$ARCHITECTURE $MODULE_DIR/docker` ]]; then
	exit 1
fi

if [[ `docker images -q $TAG:latest` != `docker images -q $TAG:build` ]]; then
	docker tag $TAG:build $TAG:`date +%Y.%m%d.%H%M`
	docker tag $TAG:build $TAG:latest
fi
docker rmi $TAG:build

exit 0