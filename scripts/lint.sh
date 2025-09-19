#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATUS=0

# Lint shell scripts
if command -v shellcheck >/dev/null 2>&1; then
  echo "Running shellcheck..."
  if ! shellcheck "${ROOT_DIR}"/scripts/*.sh; then
    STATUS=1
  fi
else
  echo "shellcheck not found; skipping shell lint" >&2
fi

# Lint GitHub workflows
if command -v yamllint >/dev/null 2>&1; then
  echo "Running yamllint..."
  if ! yamllint -s "${ROOT_DIR}/.github/workflows"; then
    STATUS=1
  fi
else
  echo "yamllint not found; skipping workflow lint" >&2
fi

# Lint Containerfiles using hadolint binary when available, otherwise fallback
# to a container runtime.
if command -v hadolint >/dev/null 2>&1; then
  echo "Running hadolint..."
  if ! hadolint "${ROOT_DIR}"/Containerfiles/Containerfile.*; then
    STATUS=1
  fi
else
  CONTAINER_TOOL=${CONTAINER_TOOL:-podman}
  if command -v "${CONTAINER_TOOL}" >/dev/null 2>&1; then
    echo "Running hadolint via container..."
    for file in "${ROOT_DIR}"/Containerfiles/Containerfile.*; do
      echo "Linting ${file}"
      if ! "${CONTAINER_TOOL}" run --rm -i ghcr.io/hadolint/hadolint < "${file}"; then
        STATUS=1
      fi
    done
  else
    echo "${CONTAINER_TOOL} not found; skipping Containerfile lint" >&2
  fi
fi

exit "${STATUS}"
