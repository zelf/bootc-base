#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
HADOLINT_IMAGE="${HADOLINT_IMAGE:-ghcr.io/hadolint/hadolint:latest}"

if ! command -v podman >/dev/null 2>&1; then
  echo "podman is required to run linting" >&2
  exit 1
fi

for file in Containerfile.base Containerfile.server Containerfile.personal; do
  echo "Linting ${file}"
  podman run --rm \
    --security-opt label=disable \
    --volume "${ROOT_DIR}/${file}:/workspace/Dockerfile:ro,z" \
    --workdir /workspace \
    "${HADOLINT_IMAGE}" \
    hadolint Dockerfile
  echo
done
