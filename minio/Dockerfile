FROM golang:1.24.8-alpine AS builder

ENV GOSUMDB=sum.golang.org

RUN GOBIN=/out go install github.com/minio/minio@RELEASE.2025-10-15T17-29-55Z

FROM ghcr.io/home-assistant/base:latest

RUN apk add --no-cache jq

COPY --from=builder /out/minio /usr/local/bin/minio
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
