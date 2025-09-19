#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTAINER_TOOL=${CONTAINER_TOOL:-podman}

if ! command -v "${CONTAINER_TOOL}" >/dev/null 2>&1; then
  echo "${CONTAINER_TOOL} is required for tests" >&2
  exit 1
fi

BASE_TAG=${BASE_TAG:-localhost/bootc-base:test}
BASE_ALIAS=${BASE_ALIAS:-bootc-base:test}
SERVER_TAG=${SERVER_TAG:-localhost/bootc-server:test}
PERSONAL_TAG=${PERSONAL_TAG:-localhost/bootc-personal:test}
TEST_IMAGES=${TEST_IMAGES:-base server personal}
TEST_IMAGES_CLEAN=$(printf '%s' "${TEST_IMAGES}" | tr ',\n' '  ')

if [[ -z "${TEST_IMAGES_CLEAN//[[:space:]]/}" ]]; then
  echo "No test images specified" >&2
  exit 1
fi

BUILD_BASE=0
BUILD_SERVER=0
BUILD_PERSONAL=0

read -r -a IMAGE_TARGETS <<< "${TEST_IMAGES_CLEAN}"

for image in "${IMAGE_TARGETS[@]}"; do
  case "${image}" in
    base)
      BUILD_BASE=1
      ;;
    server)
      BUILD_SERVER=1
      ;;
    personal)
      BUILD_PERSONAL=1
      ;;
    *)
      echo "Unknown test target: ${image}" >&2
      exit 1
      ;;
  esac
done

build_base() {
  echo "Building base image ${BASE_TAG}"
  "${CONTAINER_TOOL}" build \
    --pull=always \
    --tag "${BASE_TAG}" \
    --file "${ROOT_DIR}/Containerfiles/Containerfile.base" \
    "${ROOT_DIR}"

  if [[ "${BASE_TAG}" != "${BASE_ALIAS}" ]]; then
    "${CONTAINER_TOOL}" tag "${BASE_TAG}" "${BASE_ALIAS}"
  fi
}

ensure_base() {
  if ! "${CONTAINER_TOOL}" image exists "${BASE_ALIAS}" >/dev/null 2>&1; then
    echo "Base image ${BASE_ALIAS} not present locally; building it"
    build_base
  fi
}

build_server() {
  ensure_base
  echo "Building server image ${SERVER_TAG} from ${BASE_ALIAS}"
  "${CONTAINER_TOOL}" build \
    --build-arg BASE_IMAGE="${BASE_ALIAS}" \
    --tag "${SERVER_TAG}" \
    --file "${ROOT_DIR}/Containerfiles/Containerfile.server" \
    "${ROOT_DIR}"
}

build_personal() {
  ensure_base
  echo "Building personal image ${PERSONAL_TAG} from ${BASE_ALIAS}"
  "${CONTAINER_TOOL}" build \
    --build-arg BASE_IMAGE="${BASE_ALIAS}" \
    --tag "${PERSONAL_TAG}" \
    --file "${ROOT_DIR}/Containerfiles/Containerfile.personal" \
    "${ROOT_DIR}"
}

if (( BUILD_BASE == 1 )); then
  build_base
fi

if (( BUILD_SERVER == 1 )); then
  build_server
fi

if (( BUILD_PERSONAL == 1 )); then
  build_personal
fi

