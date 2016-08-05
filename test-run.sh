#!/bin/bash

docker build .
BUILDID="`docker build . | grep "." | tail -n 1 | sed 's/.* //'`"
echo
echo
docker run -e LANG=C.UTF-8 --rm -it -e DISPLAY --device /dev/snd --net=host -v /media/1TB/nyfilibuster/Recs:/mnt/filibuster-recs:ro "$BUILDID" bash
