#!/bin/sh

set -eu

options=/data/options.json

if ! root_user="$(jq -er '.root_user | select(type == "string") | gsub("^[[:space:]]+|[[:space:]]+$"; "") | select(length > 0)' "$options" 2>/dev/null)"; then
    printf '%s\n' 'root_user must be configured' >&2
    exit 1
fi

if ! root_password="$(jq -er '.root_password | select(type == "string") | gsub("^[[:space:]]+|[[:space:]]+$"; "") | select(length > 0)' "$options" 2>/dev/null)"; then
    printf '%s\n' 'root_password must be configured' >&2
    exit 1
fi

export MINIO_ROOT_USER="$root_user"
export MINIO_ROOT_PASSWORD="$root_password"

exec /usr/local/bin/minio server /minio/data --address :9000 --console-address :9001
