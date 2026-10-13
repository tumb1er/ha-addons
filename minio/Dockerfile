FROM golang:1.24.8-alpine AS builder

ENV GOSUMDB=sum.golang.org

ARG BUILD_ARCH
ARG TARGETARCH

RUN case "$BUILD_ARCH" in \
        amd64) expected_arch=amd64 ;; \
        aarch64) expected_arch=arm64 ;; \
        *) echo "unsupported BUILD_ARCH: $BUILD_ARCH" >&2; exit 1 ;; \
    esac && \
    [ "$TARGETARCH" = "$expected_arch" ] || { \
        echo "BUILD_ARCH $BUILD_ARCH does not match target architecture $TARGETARCH" >&2; exit 1; \
    }

RUN GOBIN=/out go install github.com/minio/minio@RELEASE.2025-10-15T17-29-55Z

FROM ghcr.io/home-assistant/base:latest

RUN apk add --no-cache jq

COPY --from=builder /out/minio /usr/local/bin/minio
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
