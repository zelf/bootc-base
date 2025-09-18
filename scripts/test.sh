#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENGINE="${CONTAINER_ENGINE:-podman}"
SECURITY_OPTS=(--security-opt label=disable)

cd "$ROOT_DIR"

$ENGINE build "${SECURITY_OPTS[@]}" --pull=always -t localhost/bootc-base:base -f Containerfiles/Containerfile.base .
$ENGINE build "${SECURITY_OPTS[@]}" --build-arg BASE_IMAGE=localhost/bootc-base:base -t localhost/bootc-base:server -f Containerfiles/Containerfile.server .
$ENGINE build "${SECURITY_OPTS[@]}" --build-arg BASE_IMAGE=localhost/bootc-base:base -t localhost/bootc-base:personal -f Containerfiles/Containerfile.personal .
