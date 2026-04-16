#!/bin/sh

PROXY_ENABLED="false"
PROXY_URL=""
NO_PROXY_CFG=""

if [ -f "/data/options.json" ]; then
    PROXY_ENABLED="$(jq -r '.proxy_enabled // false' /data/options.json 2>/dev/null || echo false)"
    PROXY_URL="$(jq -r '.proxy_url // ""' /data/options.json 2>/dev/null || echo "")"
    NO_PROXY_CFG="$(jq -r '.no_proxy // ""' /data/options.json 2>/dev/null || echo "")"
fi

if [ "${PROXY_ENABLED}" = "true" ] && [ -n "${PROXY_URL}" ]; then
    export ALL_PROXY="${PROXY_URL}"
    export HTTP_PROXY="${PROXY_URL}"
    export HTTPS_PROXY="${PROXY_URL}"
    if [ -n "${NO_PROXY_CFG}" ]; then
        export NO_PROXY="${NO_PROXY_CFG}"
    fi
else
    unset ALL_PROXY HTTP_PROXY HTTPS_PROXY NO_PROXY
fi

if [ ! -f "/transmission/config/settings.json" ]; then
    transmission-daemon \
      --no-watch-dir \
      --incomplete-dir /transmission/incomplete \
      --download-dir /transmission/downloads \
      -d \
      2>/transmission/config/settings.json

      sed -i \
        -e 's/"rpc-whitelist-enabled": true/"rpc-whitelist-enabled": false/g' \
        -e 's/"rpc-host-whitelist-enabled": true/"rpc-host-whitelist-enabled": false/g' \
        -e 's/"rpc-url": "\/transmission\/"/"rpc-url": "\/"/g' \
        /transmission/config/settings.json
fi

exec "$@"
