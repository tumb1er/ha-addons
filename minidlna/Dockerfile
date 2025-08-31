ARG BUILD_FROM=ghcr.io/hassio-addons/base:latest
FROM $BUILD_FROM

RUN apk add --no-cache minidlna

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
#ENTRYPOINT [ "/entrypoint.sh"]

STOPSIGNAL TERM
CMD [ "/entrypoint.sh", \
      "/usr/sbin/minidlnad", \
      "-d", \
      "-P", "/tmp/minidlna.pid", \
      "-f", "/config/minidlna.conf" ]
