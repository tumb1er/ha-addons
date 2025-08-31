ARG BUILD_FROM=ghcr.io/hassio-addons/base:stable
FROM $BUILD_FROM

RUN apk add --no-cache minidlna

COPY run.sh /run.sh
RUN chmod +x /run.sh

STOPSIGNAL TERM
CMD [ "/run.sh" ]
