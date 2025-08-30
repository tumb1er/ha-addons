#!/bin/sh

if [ ! -f "/transmission/config/settings.json" ]; then
    transmission-daemon \
      --no-watch-dir \
      --incomplete-dir /transmission/incomplete/ \
      --download-dir /transmission/downloads/ \
      -d \
      2>/transmission/config/settings.json
fi

exec "$@"
