#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BASE_TAG="localhost/bootc-base:base"
SERVER_TAG="localhost/bootc-base:server"
PERSONAL_TAG="localhost/bootc-base:personal"

if ! command -v podman >/dev/null 2>&1; then
  echo "podman is required to run the test builds" >&2
  exit 1
fi

podman build \
  --pull=always \
  --tag "${BASE_TAG}" \
  --file "${ROOT_DIR}/Containerfile.base" \
  "${ROOT_DIR}"

podman build \
  --tag "${SERVER_TAG}" \
  --file "${ROOT_DIR}/Containerfile.server" \
  --build-arg BASE_IMAGE="${BASE_TAG}" \
  "${ROOT_DIR}"

podman build \
  --tag "${PERSONAL_TAG}" \
  --file "${ROOT_DIR}/Containerfile.personal" \
  --build-arg BASE_IMAGE="${BASE_TAG}" \
  "${ROOT_DIR}"
