#!/bin/bash

docker build .
BUILDID="`docker build . | tail -n 1 | sed 's/.* //'`"
echo
echo
docker run "$BUILDID" "$@"
