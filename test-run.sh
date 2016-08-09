#!/bin/bash

if [ "$RECS" = "" ]; then
    RECS="/media/1TB/nyfilibuster/Recs"
fi

docker build .
BUILDID="`docker build . | grep "." | tail -n 1 | sed 's/.* //'`"
echo
echo
mkdir -p /tmp/filibuster

# for gui + sound, try with -e DISPLAY --device /dev/snd --net=host
docker run --rm -it -v "$RECS":"/mnt/filibuster-recs":ro -v "/tmp/filibuster":"/tmp" "$BUILDID" bash
