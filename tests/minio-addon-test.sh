#!/bin/sh

set -eu

fail() {
    printf '%s\n' "$1" >&2
    exit 1
}

require_line() {
    file="$1"
    line="$2"
    grep -Fqx "$line" "$file" || fail "missing required line in $file: $line"
}

static_test() {
    config="minio/config.yaml"
    dockerfile="minio/Dockerfile"

    [ -f "$config" ] || fail "missing $config"
    [ -f "$dockerfile" ] || fail "missing $dockerfile"

    require_line "$config" 'slug: "minio"'
    require_line "$config" '  - amd64'
    require_line "$config" '  - aarch64'
    require_line "$config" '  9000/tcp: 9000'
    require_line "$config" '  9001/tcp: 9001'
    require_line "$config" 'webui: "http://[HOST]:[PORT:9001]"'
    require_line "$config" '  - type: addon_config'
    require_line "$config" '    path: /minio/data'
    require_line "$config" '  root_user: str'
    require_line "$config" '  root_password: password'

    ! grep -Eq 'type: (media|share)' "$config" || fail "MinIO must not map media or share"
    grep -Fq 'github.com/minio/minio@RELEASE.2025-10-15T17-29-55Z' "$dockerfile" || fail "Dockerfile must pin the MinIO release"
    grep -Fq 'GOSUMDB=sum.golang.org' "$dockerfile" || fail "Dockerfile must verify Go module checksums"
}

case "${1:-}" in
    --static)
        static_test
        ;;
    *)
        fail "usage: $0 --static"
        ;;
esac
