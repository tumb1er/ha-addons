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
    grep -Fq 'ARG BUILD_ARCH' "$dockerfile" || fail "Dockerfile must declare BUILD_ARCH"

    build_output="$(mktemp)"
    if docker build --build-arg BUILD_ARCH=armhf minio >"$build_output" 2>&1; then
        rm -f "$build_output"
        fail "Dockerfile accepted unsupported BUILD_ARCH=armhf"
    fi
    grep -Fq 'unsupported BUILD_ARCH: armhf' "$build_output" || fail "unsupported architecture did not produce a clear error"
    rm -f "$build_output"
}

wait_for_http() {
    url="$1"
    attempts=0

    while [ "$attempts" -lt 30 ]; do
        if curl --fail --silent --location --output /dev/null "$url"; then
            return 0
        fi
        attempts=$((attempts + 1))
        sleep 1
    done

    fail "service did not become ready at $url"
}

runtime_test() {
    image="ha-addons-minio-test:runtime"
    tmpdir="$(mktemp -d)"
    container=""
    secret="must-not-appear-in-logs"

    cleanup() {
        if [ -n "$container" ]; then
            docker rm --force "$container" >/dev/null 2>&1 || true
        fi
        docker run --rm -v "$tmpdir:/cleanup" --entrypoint /bin/sh "$image" -c 'rm -rf /cleanup/data' >/dev/null 2>&1 || true
        rm -rf "$tmpdir"
    }
    trap cleanup EXIT INT TERM

    docker build --build-arg BUILD_ARCH=amd64 --tag "$image" minio

    mkdir -p "$tmpdir/options" "$tmpdir/data"
    assert_invalid_options() {
        expected_message="$1"
        options_json="$2"
        printf '%s\n' "$options_json" > "$tmpdir/options/options.json"
        set +e
        invalid_output="$(timeout 10 docker run --rm --entrypoint /entrypoint.sh -v "$tmpdir/options:/data:ro" "$image" 2>&1)"
        invalid_status=$?
        set -e
        [ "$invalid_status" -ne 0 ] || fail "entrypoint accepted invalid credentials"
        ! printf '%s' "$invalid_output" | grep -Fq "$secret" || fail "entrypoint logged the root password"
        printf '%s' "$invalid_output" | grep -Fqx "$expected_message" || fail "entrypoint did not reject invalid credentials"
    }

    assert_invalid_options 'root_user must be configured' "{\"root_user\":\"   \",\"root_password\":\"$secret\"}"
    assert_invalid_options 'root_password must be configured' '{"root_user":"minioadmin","root_password":"   "}'

    printf '{"root_user":"minioadmin","root_password":"strong-test-password"}\n' > "$tmpdir/options/options.json"
    container="$(docker run --detach -v "$tmpdir/options:/data:ro" -v "$tmpdir/data:/minio/data" -p 127.0.0.1::9000 -p 127.0.0.1::9001 "$image")"
    api_port="$(docker port "$container" 9000/tcp | sed -n 's/.*:\([0-9][0-9]*\)$/\1/p')"
    console_port="$(docker port "$container" 9001/tcp | sed -n 's/.*:\([0-9][0-9]*\)$/\1/p')"
    wait_for_http "http://127.0.0.1:$api_port/minio/health/live"
    wait_for_http "http://127.0.0.1:$console_port/"
    python3 tests/minio-s3-smoke.py "http://127.0.0.1:$api_port" create
    docker rm --force "$container" >/dev/null
    container=""

    container="$(docker run --detach -v "$tmpdir/options:/data:ro" -v "$tmpdir/data:/minio/data" -p 127.0.0.1::9000 "$image")"
    api_port="$(docker port "$container" 9000/tcp | sed -n 's/.*:\([0-9][0-9]*\)$/\1/p')"
    wait_for_http "http://127.0.0.1:$api_port/minio/health/live"
    python3 tests/minio-s3-smoke.py "http://127.0.0.1:$api_port" verify
    printf '%s\n' "runtime-pass"
}

case "${1:-}" in
    --static)
        static_test
        ;;
    --runtime)
        runtime_test
        ;;
    *)
        fail "usage: $0 --static"
        ;;
esac
