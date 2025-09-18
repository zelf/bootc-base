# Bootc Images Contribution Guide

## Repo expectations

* All image builds must start from `quay.io/fedora/fedora-bootc:42` and use **`dnf5`** for package operations.
* Keep the Nano-to-Vim swap, tmux, Tailscale, and Firewalld present in every variant. The server and personal images should inherit from the base image via the `BASE_IMAGE` build argument.
* When changing any Containerfile, mirror the update in the README so the documentation matches reality.
* Systemd services should be enabled or masked with `systemctl enable` / `systemctl mask` inside the Containerfiles (never rely on runtime steps).

## Testing

Always run (or at least attempt to run) the helper scripts before sending changes:

```bash
sudo bash scripts/lint.sh
sudo bash scripts/test.sh
```

They lint the Containerfiles with Hadolint and attempt Podman builds for the base, server, and personal variants.

## CI/CD

GitHub Actions executes the same scripts on pull requests and publishes images to GHCR only after merges to `main`. Keep those workflows green.
