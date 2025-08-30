ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM $BUILD_FROM

RUN apk add --no-cache minidlna

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh"]

USER nobody

STOPSIGNAL TERM
CMD [ "/usr/sbin/minidlnad", "-d", "-P", "/config/minidlna.pid", "-f", "/config/minidlna.conf" ]
