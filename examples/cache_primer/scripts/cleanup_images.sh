#!/bin/bash

function log
{
    echo -e "$1"
}

function error
{
    log "$1"
    exit 2
}

function usage
{
    log "Usage: $0 <base cache image name> <parent os base image>"
    log "\nTo see the current docker images : docker images"
    log "\nRun docker images to see what cache image and os image to retain"
    log "The os type and base image have to be explicit to protect the docker image cache."
    error "\nDeleting the cached image will result in longer build times"
}

function verify
{
    local result=$1
    local error_msg=$2

    if [ ${result} -ne 0 ];then
        log "${error_msg}"
    fi
}

if [ $# -ne 2 ];then
    log "Wrong number of arguments, got [$#] expected [2]"
    usage
fi

OPT_BASE=$1
OPT_OS=$2

num_containers=$(docker ps -aq | wc -l)
if [ ${num_containers} -gt 0 ];then
    log "Found ${num_containers} containers .. Removing"
    docker rm --force $(docker ps -aq)
    verify $? "Failed to remove the docker containers. Please run docker ps -aq and docker rm --force the results"
fi

num_images=$(docker images | grep -v REPOSITORY | grep -v ${OPT_BASE} | grep -v ${OPT_OS} | wc -l)
if [ ${num_images} -gt 0 ];then
    log "Found ${num_images} images .. Removing"
    docker rmi $(docker images | grep -v REPOSITORY | grep -v ${OPT_BASE} | grep -v ${OPT_OS} | awk '{ print $3 }')
    verify $? "Failed to remove the docker images. Please run docker images and perform a docker rmi manually"
fi

log "Cleanup complete"