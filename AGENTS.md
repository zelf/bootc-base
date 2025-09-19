# Bootc Image Agent Specification

## Base

- **Upstream base:** `quay.io/fedora/fedora-bootc:42`
- **Image type:** OCI bootable container
- **Registry:** `ghcr.io/<owner>/bootc-*` (owner resolved from the GitHub repository)
- **Update policy:** Automatic via `bootc-fetch-apply-updates.timer`
- **Rollback:** Supported by bootc
- **Target user:** `zelf` (device specific configuration supplied later)
- **Partitioning:** Hardened custom layout (documented during host provisioning)

---

## Common base (all variants)

### Filesystem overlays
- `files/common/` sets Vim as the default editor, provides a shared tmux profile,
  disables `tailscaled` by default, and leaves SELinux enforcing.

### Packages
- Remove: `nano-default-editor`
- Add: `vim-enhanced`, `vim-default-editor`, `tmux`, `tailscale`, `firewalld`
- Manage all package changes with `dnf5` during image builds.

### Services
- `firewalld` enabled and active
- `bootc-fetch-apply-updates.timer` enabled for automatic updates
- `tailscaled` disabled (variants enable it selectively)

---

## Variant: Server base

### Additional packages
- `fail2ban`, `podman`, `aide`, `setools-console`

### Filesystem overlays (`files/server/`)
- Hardened SSH configuration (`sshd_config.d`, service override)
- Fail2ban jail tuned for SSH
- Locked down firewalld zone (`bootc-server`) permitting SSH only
- Kernel/network sysctl defaults tightened for server workloads

### Services
- `sshd` enabled
- `fail2ban` enabled
- `tailscaled` kept disabled unless the deployment overrides the preset

---

## Variant: Personal device base

### Additional packages
- `flatpak`, `toolbox`, `zsh`, `git`

### Filesystem overlays (`files/personal/`)
- Personal firewalld defaults for trusted local networks
- NetworkManager Wi-Fi power save tuning
- Tailscale service drop-in ensuring startup after networking

### Services
- `tailscaled` enabled for connectivity
- `sshd` disabled by default

---

## Build and publish flow

### Local helpers
- `scripts/lint.sh` runs shellcheck, yamllint, and hadolint (using a container
  fallback when the binary is unavailable).
- `scripts/test.sh` builds the base image first, then the server and personal
  variants using the freshly built base (configurable via environment
  variables like `CONTAINER_TOOL`, `BASE_ALIAS`, and `TEST_IMAGES`).

### GitHub workflows
- `.github/workflows/ci.yml` triggers on pull requests to `main`, installs
  tooling, runs the lint script, builds the base image, and then builds the
  server and personal variants in parallel using the uploaded base artifact.
- `.github/workflows/release.yml` surfaces as a PR check via
  `pull_request_target` but only builds on a manual `workflow_dispatch`. The
  dispatch auto-detects the pull request number from the branch (or accepts an
  override) before building/pushing the base image, then running the server and
  personal jobs in parallel. When no Containerfile changes are detected the
  workflow reuses the existing GHCR image tags. Successful runs automatically
  merge the resolved pull request into `main`.

### Publishing
- Release builds push commit-SHA and `latest` tags for each image to
  `ghcr.io/<owner>/bootc-{base,server,personal}`.
- Local builds can be tagged with the same naming scheme before pushing.

---

## Partition layout (hardened)

> Manual installs will enforce the hardened scheme during host provisioning.
- `/boot` separate
- `/var` separate
- `/home` separate (encryption recommended)
- `/` minimal
- `tmpfs` for `/tmp`

---

## Git commit guidelines

Follow the “How to Write a Git Commit Message” rules by Chris Beams.

1. Separate subject from body with a blank line.
2. Limit subject line to **50 characters**.
3. Capitalize the subject line.
4. Do *not* end subject line with a period.
5. Use the imperative mood in the subject line (e.g. “Add”, “Remove”, “Fix”).
6. Wrap the body at **72 characters**.
7. Use the body to explain *what* and *why* instead of *how*.

### Template suggestion

```text
<Subject (Imperative, ≤50 chars, Capitalized, no period)>

<Body: explain what and why. Wrap at 72 chars. May include
- Side effects
- Dependencies
- Issue/ticket IDs (if used)
```
