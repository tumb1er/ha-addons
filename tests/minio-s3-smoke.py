#!/usr/bin/env python3

import datetime as dt
import hashlib
import hmac
import sys
import urllib.parse
import urllib.request


ACCESS_KEY = "minioadmin"
SECRET_KEY = "strong-test-password"
REGION = "us-east-1"
SERVICE = "s3"
BUCKET = "minio-smoke"
OBJECT_PATH = f"/{BUCKET}/persist.txt"
OBJECT_CONTENT = b"persistent object\n"


def sign(key: bytes, value: str) -> bytes:
    return hmac.new(key, value.encode(), hashlib.sha256).digest()


def request(endpoint: str, method: str, path: str, body: bytes = b"") -> bytes:
    parsed = urllib.parse.urlsplit(endpoint)
    now = dt.datetime.now(dt.timezone.utc)
    timestamp = now.strftime("%Y%m%dT%H%M%SZ")
    date = now.strftime("%Y%m%d")
    payload_hash = hashlib.sha256(body).hexdigest()
    canonical_uri = urllib.parse.quote(path, safe="/-_.~")
    canonical_headers = (
        f"host:{parsed.netloc}\n"
        f"x-amz-content-sha256:{payload_hash}\n"
        f"x-amz-date:{timestamp}\n"
    )
    signed_headers = "host;x-amz-content-sha256;x-amz-date"
    canonical_request = "\n".join(
        [method, canonical_uri, "", canonical_headers, signed_headers, payload_hash]
    )
    scope = f"{date}/{REGION}/{SERVICE}/aws4_request"
    string_to_sign = "\n".join(
        ["AWS4-HMAC-SHA256", timestamp, scope, hashlib.sha256(canonical_request.encode()).hexdigest()]
    )
    signing_key = sign(sign(sign(sign(("AWS4" + SECRET_KEY).encode(), date), REGION), SERVICE), "aws4_request")
    signature = hmac.new(signing_key, string_to_sign.encode(), hashlib.sha256).hexdigest()
    authorization = (
        "AWS4-HMAC-SHA256 "
        f"Credential={ACCESS_KEY}/{scope}, "
        f"SignedHeaders={signed_headers}, Signature={signature}"
    )
    headers = {
        "Host": parsed.netloc,
        "x-amz-content-sha256": payload_hash,
        "x-amz-date": timestamp,
        "Authorization": authorization,
    }
    with urllib.request.urlopen(urllib.request.Request(endpoint + canonical_uri, body, headers, method=method)) as response:
        return response.read()


def main() -> None:
    endpoint, command = sys.argv[1:3]
    if command == "create":
        request(endpoint, "PUT", f"/{BUCKET}")
        request(endpoint, "PUT", OBJECT_PATH, OBJECT_CONTENT)
    elif command == "verify":
        if request(endpoint, "GET", OBJECT_PATH) != OBJECT_CONTENT:
            raise RuntimeError("persisted S3 object content changed")
    else:
        raise ValueError(f"unknown command: {command}")


if __name__ == "__main__":
    main()
