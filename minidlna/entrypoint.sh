#!/bin/sh

if [ ! -f "/config/minidlna.conf" ]; then
    cat /etc/minidlna.conf | sed \
      -e 's/#friendly_name=My DLNA Server/friendly_name=HA/g' \
      -e 's/#enable_subtitles=yes/enable_subtitles=no/g' \
      -e 's/#db_dir=\/var\/cache\/minidlna/db_dir=\/config\/minidlna/g' \
      -e 's/notify_interval=900/notify_interval=60/g' \
      > /config/minidlna.conf
fi

exec "$@"
