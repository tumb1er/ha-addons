# MinIO Add-on Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a Home Assistant add-on that exposes a persistent MinIO S3 service and Console on host ports 9000 and 9001.

**Architecture:** The add-on uses a Home Assistant base image plus a pinned MinIO server binary selected by `BUILD_ARCH`. Its POSIX entrypoint obtains mandatory root credentials from `/data/options.json` and execs a single-node MinIO server against the private `/minio/data` mount. A Docker-backed smoke test is the executable contract for the manifest and process.

**Tech Stack:** Home Assistant add-on manifest YAML, Alpine shell and `jq`, Docker, pinned MinIO Linux binaries.

**Spec:** `docs/superpowers/specs/2026-10-13-minio-addon-design.md`

## Global Constraints

- Declare only `amd64` and `aarch64` architectures.
- Publish `9000/tcp` for S3 and `9001/tcp` for the Console.
- Map writable `addon_config` storage to `/minio/data`; do not map `media` or `share`.
- Accept `root_user` and `root_password` as mandatory Home Assistant options; `root_password` uses the `password` schema type.
- Pin the MinIO release and verify its checksum while building.
- Do not log root credentials.
- Start `minio server /minio/data --address :9000 --console-address :9001`.
- Do not add TLS, reverse proxying, distributed mode, or bucket/user bootstrap logic.

## Review Focus

- Missing or empty `root_password`: startup must fail without outputting the supplied value; covered in Task 2's invalid-options test.
- Port remapping by Supervisor: the manifest must state both container ports and a `webui` URL for the Console; covered in Task 1's manifest assertions.
- A restart with the same private storage: existing S3 objects and MinIO metadata must be retained; covered in Task 2's two-container persistence check.
- Unsupported architecture: a build must fail rather than download an incorrect binary; covered in Task 1's Dockerfile architecture-case assertion.
- Accidentally exposed HA media/share: the manifest must have no such maps; covered in Task 1's manifest assertions.

---

## File Structure

- `minio/config.yaml` — Home Assistant add-on identity, architecture, port, storage, and options contract.
- `minio/Dockerfile` — pinned, checksum-verified MinIO binary installation for the selected build architecture.
- `minio/entrypoint.sh` — credential validation and MinIO process launch.
- `minio/README.md` — operator-facing setup, endpoints, storage, and security guidance.
- `tests/minio-addon-test.sh` — static manifest assertions and Docker runtime smoke tests.

### Task 1: Define the add-on image and Supervisor contract

**Files:**
- Create: `minio/config.yaml`
- Create: `minio/Dockerfile`
- Test: `tests/minio-addon-test.sh`

**Interfaces:**
- Consumes: Home Assistant `BUILD_ARCH`, `/data/options.json`, and the Supervisor `map`/`ports` schema.
- Produces: an image containing executable `/usr/local/bin/minio`; a manifest whose slug is `minio`, maps `/minio/data`, and exposes S3/Console ports.

- [ ] **Step 1: Write the failing static-manifest assertions in `tests/minio-addon-test.sh`**

Assert that `minio/config.yaml` contains `slug: minio`, `amd64` and `aarch64`, `9000/tcp: 9000`, `9001/tcp: 9001`, `webui: http://[HOST]:[PORT:9001]`, an `addon_config` map to `/minio/data`, and no `media` or `share` maps. Assert that the Dockerfile rejects unknown `BUILD_ARCH` values and verifies a pinned release checksum.

- [ ] **Step 2: Run the static test to verify it fails**

Run: `sh tests/minio-addon-test.sh --static`

Expected: FAIL because the MinIO manifest and Dockerfile do not exist.

- [ ] **Step 3: Implement `minio/config.yaml` and `minio/Dockerfile`**

Use explicit `FROM ghcr.io/home-assistant/base:latest`. Add `jq` and the downloader required by the Dockerfile. Map `BUILD_ARCH=amd64` to MinIO's `linux-amd64` artifact and `BUILD_ARCH=aarch64` to `linux-arm64`; reject all others. Download the fixed release and its upstream SHA-256 manifest, then check the downloaded binary before installing it at `/usr/local/bin/minio`.

Define mandatory `root_user: str` and `root_password: password`, set `init: false`, set `webui` to the Console port template, and include human-readable descriptions for both ports.

- [ ] **Step 4: Run the static test to verify it passes**

Run: `sh tests/minio-addon-test.sh --static`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add minio/config.yaml minio/Dockerfile tests/minio-addon-test.sh
git commit -m "feat: add MinIO add-on manifest"
```

### Task 2: Implement guarded MinIO startup and runtime smoke coverage

**Files:**
- Create: `minio/entrypoint.sh`
- Modify: `minio/Dockerfile`
- Modify: `tests/minio-addon-test.sh`

**Interfaces:**
- Consumes: `/data/options.json` with JSON keys `root_user` and `root_password`; `/usr/local/bin/minio` from Task 1.
- Produces: `/entrypoint.sh`, which exits non-zero for absent/empty credentials and otherwise execs MinIO on the contract ports using `/minio/data`.

- [ ] **Step 1: Extend `tests/minio-addon-test.sh` with failing runtime cases**

Build the add-on image with `--build-arg BUILD_ARCH=amd64`. Assert an empty or absent credentials file causes `/entrypoint.sh` to exit non-zero without echoing the password. With temporary directories mounted at `/data` and `/minio/data`, start the image and poll `http://127.0.0.1:<mapped-9000>/minio/health/live` for HTTP 200 and `http://127.0.0.1:<mapped-9001>/` for a successful Console response. Restart against the same data directory and assert the health endpoint remains healthy.

- [ ] **Step 2: Run the runtime test to verify it fails**

Run: `sh tests/minio-addon-test.sh --runtime`

Expected: FAIL because the image has no guarded entrypoint.

- [ ] **Step 3: Implement `/entrypoint.sh` and connect it from the Dockerfile**

Use `jq -er` to read `root_user` and `root_password`; reject missing, null, or empty values with a credential-free diagnostic. Export them only as `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD`, then `exec /usr/local/bin/minio server /minio/data --address :9000 --console-address :9001`. Copy the script into the image, mark it executable, and set it as `ENTRYPOINT`.

- [ ] **Step 4: Run static and runtime tests to verify they pass**

Run: `sh tests/minio-addon-test.sh --static && sh tests/minio-addon-test.sh --runtime`

Expected: PASS; Docker containers and temporary directories are removed by the test trap.

- [ ] **Step 5: Commit**

```bash
git add minio/entrypoint.sh minio/Dockerfile tests/minio-addon-test.sh
git commit -m "feat: run MinIO with configured credentials"
```

### Task 3: Document installation and operating boundaries

**Files:**
- Create: `minio/README.md`
- Test: `tests/minio-addon-test.sh`

**Interfaces:**
- Consumes: ports and credentials contract from Tasks 1–2.
- Produces: concise operator documentation that mirrors the shipped add-on behavior.

- [ ] **Step 1: Add failing documentation assertions to `tests/minio-addon-test.sh`**

Assert that the README names the S3 endpoint `http://<HA-host>:9000`, the Console endpoint `http://<HA-host>:9001`, both root options, `/minio/data` persistence, and the absence of bundled TLS.

- [ ] **Step 2: Run the documentation check to verify it fails**

Run: `sh tests/minio-addon-test.sh --docs`

Expected: FAIL because the MinIO README does not exist.

- [ ] **Step 3: Implement `minio/README.md`**

Describe add-on installation, setting a unique root username and strong password, the two host endpoints, isolated persistent bucket storage, and the requirement to use network restrictions or a reverse proxy for remote/TLS access. State that this is a single-node service and that changing root options takes effect when the add-on restarts.

- [ ] **Step 4: Run all tests to verify they pass**

Run: `sh tests/minio-addon-test.sh --static && sh tests/minio-addon-test.sh --runtime && sh tests/minio-addon-test.sh --docs`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add minio/README.md tests/minio-addon-test.sh
git commit -m "docs: document MinIO add-on"
```
