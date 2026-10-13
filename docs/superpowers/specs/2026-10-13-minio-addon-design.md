# MinIO Home Assistant add-on design

## Goal

Add a self-contained MinIO add-on to this repository.  It must expose a
single-node, S3-compatible object store and the MinIO Console on host ports,
while keeping bucket data isolated from Home Assistant's shared `media` and
`share` directories.

## Scope and constraints

- The add-on is installed from this repository alongside the existing
  add-ons.
- The S3 API is published as `9000/tcp`; the Console is published as
  `9001/tcp`.
- Persistent bucket data is supplied by an `addon_config` mount at
  `/minio/data`.  This mirrors Transmission's private configuration mount,
  without making MinIO data part of its media or share mounts.
- The root access key and secret are supplied through the Home Assistant
  add-on options, not embedded in the image or repository.
- The initial implementation supports `amd64` and `aarch64`, the target
  architectures with official MinIO container support.
- TLS, reverse-proxy configuration, multi-node MinIO, and automatic bucket or
  user provisioning are explicitly out of scope.

## Add-on layout

`minio/` will contain:

- `config.yaml`: Home Assistant metadata, the two host ports, the private
  storage mapping, and option schema for `root_user` and `root_password`.
- `Dockerfile`: a pinned official MinIO image or binary build compatible with
  the declared architectures.
- `entrypoint.sh`: reads the supervised options from `/data/options.json`,
  exports `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD`, and replaces itself
  with MinIO.
- `README.md`: installation, endpoints, credential setup, persistence, and
  security notes.

## Runtime behaviour

At startup the entrypoint requires non-empty configured credentials.  It
launches:

```text
minio server /minio/data --address :9000 --console-address :9001
```

The server therefore accepts S3 clients at `http://<ha-host>:9000` and
provides Console at `http://<ha-host>:9001`.  MinIO owns all bucket and IAM
metadata below `/minio/data`; restarts preserve it.  A startup validation
failure must print a clear error and exit rather than starting with MinIO's
default credentials.

## Security and errors

Credentials are declared with Home Assistant's password-aware option schema
and never logged.  Both ports are deliberately LAN-exposed at the user's
request, so the README states that the add-on does not terminate TLS and
should be placed behind a reverse proxy or restricted network when remote
access is needed.  It also documents that changing the root credentials in
the add-on configuration changes the environment MinIO receives at its next
start.

## Verification

Automated checks will validate the add-on manifest, ensure both required
ports and the isolated storage map are present, and exercise entrypoint input
validation without logging secrets.  A container smoke test, when Docker is
available, starts MinIO with temporary data, verifies `/minio/health/live`,
and confirms that the Console is bound to `9001`.
