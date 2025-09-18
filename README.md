# bootc-base

Bootable container recipes that track Fedora 42 and provide hardened system
images for zelf managed systems. The repository produces three OCI images:

- `bootc-base`: common hardened baseline shared by all variants.
- `bootc-server`: secure defaults for headless servers and services.
- `bootc-personal`: developer friendly personal device image with the same
  hardened core.

All images layer on top of `quay.io/fedora/fedora-bootc:42`, switch the default
editor to Vim, install tmux with mouse support, and ship with firewalld and
Tailscale preconfigured.

## Repository layout

```
Containerfiles/                 # bootc Containerfiles for each variant
files/common/                   # Shared filesystem overlays for all images
files/server/                   # Server specific configuration overlays
files/personal/                 # Personal device configuration overlays
scripts/                        # linting and build verification helpers
.github/workflows/              # CI and release automation
```

## Image contents

### Common base (`Containerfiles/Containerfile.base`)

- Removes `nano-default-editor` in favour of `vim-default-editor`.
- Installs `vim-enhanced`, `tmux`, `tailscale`, and `firewalld`.
- Enables `firewalld` and the `bootc-fetch-apply-updates.timer` timer.
- Ensures `tailscaled` stays disabled unless explicitly enabled downstream.
- Provides `/etc/tmux.conf` with mouse and vi mode defaults and sets the
  `EDITOR`/`VISUAL` environment variables to Vim for interactive sessions.

### Server variant (`Containerfiles/Containerfile.server`)

- Builds on the base image and adds server tooling: `podman`, `fail2ban`,
  `aide`, and `setools-console`.
- Enables `sshd` and `fail2ban` by default while keeping `tailscaled` disabled.
- Ships hardened SSH settings (no password or root login, aggressive
  disconnects) and a Fail2ban jail tuned for SSH.
- Installs stricter kernel sysctl defaults and applies a locked down
  firewalld zone (`bootc-server`) that allows only SSH by default.

### Personal variant (`Containerfiles/Containerfile.personal`)

- Adds workstation conveniences: `flatpak`, `toolbox`, `zsh`, and `git`.
- Keeps `sshd` disabled while enabling `tailscaled` for device connectivity.
- Adjusts firewalld defaults to a trusted local network profile that still
  blocks forwarding.
- Configures NetworkManager for balanced Wi-Fi power save settings and ensures
  Tailscale starts after the network stack is fully online.

## Building locally

1. Install `podman` (or another OCI compatible builder) and ensure you can run
   rootless or privileged builds.
2. Run the verification script:

   ```bash
   scripts/test.sh
   ```

   The script builds the base image first and uses it for the server and
   personal variants. Override `CONTAINER_TOOL` if you prefer `buildah`.
3. Tag or push the resulting images as required, for example:

   ```bash
   podman tag localhost/bootc-server:test ghcr.io/zelf/bootc-server:test
   ```

To build a variant directly against the published base, specify the
`BASE_IMAGE` argument:

```bash
podman build --build-arg BASE_IMAGE=ghcr.io/zelf/bootc-base:latest \
  -f Containerfiles/Containerfile.server .
```

## Continuous integration and delivery

- Pull requests targeting `main` run `scripts/lint.sh` and `scripts/test.sh`
  via GitHub Actions (see `.github/workflows/ci.yml`).
- The release workflow (`.github/workflows/release.yml`) appears in the PR
  checks list via `pull_request_target`, but it only builds when a maintainer
  manually dispatches it. Manual runs auto-detect the associated pull request,
  build/push the base image first, then fan out to the server and personal
  variants before merging the PR on success. Existing GHCR tags are reused if
  the corresponding Containerfiles stay untouched.

## Operational notes & hardening follow-ups

- Initialise `aide` after first boot to generate its baseline database.
- Consider enabling automatic `tailscaled` start on the server variant only on
  hosts that require it by overriding the preset.
- Review and tailor firewalld rules for workloads that require additional
  ingress (e.g. HTTP/HTTPS on application servers).
- For personal devices with graphical environments, extend the variant with a
  desktop stack (GNOME, KDE, etc.) or developer tooling suites as needed.
- Evaluate adding `fapolicyd`, `usbguard`, or compliance profiles from
  `scap-security-guide` for stricter environments.
- Integrate secret management (e.g. `sops` + `age`) once device specific
  configurations are layered on top of these bases.

## Next steps / improvement ideas

- Create host-specific bootc manifests or system extensions that leverage these
  images (e.g. provisioning scripts, ignition files, or Butane templates).
- Automate validation of firewall and SELinux policies using `oscap` or
  OpenSCAP profiles in CI to catch regressions early.
- Provide sample Tailscale auth keys via GitHub environments and extend the
  release workflow to sign images with `cosign` for supply chain assurances.
- Document partitioning recipes for the hardened layout referenced in
  `AGENTS.md`, potentially via Anaconda kickstarts or `butane` configs.
