# MinIO

MinIO provides S3-compatible object storage and the MinIO Console as a Home
Assistant add-on.

## Setup

1. Install **MinIO** from this repository and start the add-on configuration.
2. Set `root_user` to a unique administrator access key.
3. Set `root_password` to a strong, unique administrator secret.
4. Start the add-on.

Both options are required. Changes to either root credential take effect when
the add-on restarts.

## Endpoints

- S3 API: `http://<HA-host>:9000`
- MinIO Console: `http://<HA-host>:9001`

Sign in to the Console using `root_user` and `root_password`. Use the S3 API
endpoint with an S3 client or SDK.

## Storage

Bucket objects, MinIO configuration, and IAM metadata are stored persistently
at `/minio/data`. This is an add-on-specific mount and is deliberately kept
separate from Home Assistant's `media` and `share` directories.

This add-on runs one standalone MinIO server. It does not configure distributed
MinIO clusters, create buckets, or create additional users automatically.

## Security

The S3 API and Console are exposed on host ports. The add-on does not include
TLS termination. Keep access on a trusted network; for remote access, put the
service behind a TLS-capable reverse proxy or otherwise restrict network access.
