#!/usr/bin/with-contenv bashio

declare ingress_port
ingress_port=$(bashio::addon.ingress_port)

cat /etc/minidlna.conf | sed \
  -e 's/#friendly_name=My DLNA Server/friendly_name=HA/g' \
  -e 's/#enable_subtitles=yes/enable_subtitles=no/g' \
  -e 's/#db_dir=\/var\/cache\/minidlna/db_dir=\/config\/minidlna/g' \
  -e 's/notify_interval=900/notify_interval=60/g' \
  -e "s/port=8200/port=%{ingress_port}/g" \
  > /config/minidlna.conf

exec /usr/sbin/minidlnad -d -P /tmp/minidlna.pid -f /config/minidlna.conf
