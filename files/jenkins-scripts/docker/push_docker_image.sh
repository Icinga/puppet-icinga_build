#!/bin/bash

set -x

: ${END:=5}
: ${image_name:=}
: ${PUSH_IMAGE:=0}
: ${DOCKER_REGISTRY:=}
: ${PUBLISH:=}

if [ -z ${image_name} ]; then
  echo "image_name not set!" >&2
  exit 1
fi

if [ ${PUBLISH} = true ]; then
  if [ -z ${DOCKER_REGISTRY} ]; then
    echo "DOCKER_REGISTRY is not configured!" >&2
    exit 1
  fi

  docker tag ${image_name} ${DOCKER_REGISTRY}/${image_name}

  pushed=0
  for i in $(seq 1 ${END}); do
    if docker push ${DOCKER_REGISTRY}/${image_name}; then
      pushed=1
      break
    fi
    sleep 30
  done
  
  docker rmi ${image_name}
  docker rmi ${DOCKER_REGISTRY}/${image_name}
  
  if [ "$pushed" != "1" ]; then
  	exit 1
  fi
else
  echo "Skipping publish, it is not enabled, see PUBLISH parameter!"
fi
