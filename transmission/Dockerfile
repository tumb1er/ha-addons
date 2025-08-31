ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM $BUILD_FROM

RUN mkdir -p /transmission/config /transmission/downloads /transmission/incomplete
RUN chown nobody:root /transmission/config

VOLUME /transmission/downloads
VOLUME /transmission/incomplete

RUN apk update && \
    apk add --no-cache transmission-daemon

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

STOPSIGNAL SIGTERM
CMD ["/usr/bin/transmission-daemon", "--foreground", "--config-dir", "/transmission/config"]
