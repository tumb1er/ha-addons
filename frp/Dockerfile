ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM $BUILD_FROM
ARG BUILD_ARCH=amd64
ARG FRP_VERSION=0.64.0

COPY build.sh /

RUN chmod a+x /build.sh

RUN /build.sh $BUILD_ARCH $FRP_VERSION

CMD ["/usr/local/bin/frpc", "-c", "/config/frpc.toml"]
