#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENGINE="${CONTAINER_ENGINE:-podman}"
IMAGE="docker.io/hadolint/hadolint:latest"

cd "$ROOT_DIR"

$ENGINE run --rm --net=none -v "$ROOT_DIR":/work:ro -w /work "$IMAGE" \
  Containerfiles/Containerfile.base \
  Containerfiles/Containerfile.server \
  Containerfiles/Containerfile.personal
