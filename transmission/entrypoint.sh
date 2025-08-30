#!/bin/sh

if [ ! -f "/transmission/config/settings.json" ]; then
    transmission-daemon \
      --no-watch-dir \
      --incomplete-dir /transmission/incomplete/ \
      --download-dir /transmission/downloads/ \
      -d \
      2>/transmission/config/settings.json

      sed -i \
        -e 's/"rpc-whitelist-enabled": true/"rpc-whitelist-enabled": false/g' \
        -e 's/"rpc-host-whitelist-enabled": true/"rpc-host-whitelist-enabled": false/g' \
        -e 's/"rpc-url": "\/transmission\/"/"rpc-url": "\/"/g' \
        /transmission/config/settings.json
fi

exec "$@"
