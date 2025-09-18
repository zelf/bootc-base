#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTAINER_TOOL=${CONTAINER_TOOL:-podman}

if ! command -v "${CONTAINER_TOOL}" >/dev/null 2>&1; then
  echo "${CONTAINER_TOOL} is required for tests" >&2
  exit 1
fi

BASE_TAG=${BASE_TAG:-localhost/bootc-base:test}
SERVER_TAG=${SERVER_TAG:-localhost/bootc-server:test}
PERSONAL_TAG=${PERSONAL_TAG:-localhost/bootc-personal:test}

# Build the common base image
"${CONTAINER_TOOL}" build \
  --pull=always \
  --tag "${BASE_TAG}" \
  --file "${ROOT_DIR}/Containerfiles/Containerfile.base" \
  "${ROOT_DIR}"

# Ensure a generic tag is available for downstream builds
"${CONTAINER_TOOL}" tag "${BASE_TAG}" bootc-base:test >/dev/null 2>&1 || true

# Build the server variant using the freshly built base
"${CONTAINER_TOOL}" build \
  --build-arg BASE_IMAGE="bootc-base:test" \
  --tag "${SERVER_TAG}" \
  --file "${ROOT_DIR}/Containerfiles/Containerfile.server" \
  "${ROOT_DIR}"

# Build the personal variant using the freshly built base
"${CONTAINER_TOOL}" build \
  --build-arg BASE_IMAGE="bootc-base:test" \
  --tag "${PERSONAL_TAG}" \
  --file "${ROOT_DIR}/Containerfiles/Containerfile.personal" \
  "${ROOT_DIR}"

