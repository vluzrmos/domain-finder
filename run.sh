#!/bin/bash

DOMFINDER_DOCKER_RUN_ARGS=${DOMFINDER_DOCKER_RUN_ARGS:-"-q --rm"}

docker run ${DOMFINDER_DOCKER_RUN_ARGS} vluzrmos/domain-finder:latest $@