# bootc-base

This repository defines a hardened [bootc](https://bootc-org.github.io/) image family derived from `quay.io/fedora/fedora-bootc:42`. The layout produces a reusable common base image plus two opinionated variants: a server build and a personal-device build. All images install Vim in place of Nano, provide tmux with mouse support, and include Tailscale and Firewalld with update automation enabled out of the box. Package layering is handled with `dnf5` so the images stay aligned with modern Fedora tooling.

## Image layout

| Image tag | Description |
| --- | --- |
| `base` | Common baseline that removes Nano, installs `vim-enhanced`, `tailscale`, `firewalld`, and `tmux`, enables automatic bootc updates, and leaves `tailscaled` disabled by default. |
| `server` | Extends the base with server-focused hardening: installs `fail2ban`, Podman, Cockpit, SELinux tooling, and SCAP content; enables `sshd`, `fail2ban`, and `cockpit.socket`; masks `tailscaled`; applies a restrictive firewalld public zone and default systemd lockdown options. |
| `personal` | Extends the base with personal productivity and mobility tools: installs Podman, Flatpak, Zsh, WireGuard tools, and TLP; enables `tailscaled` and `tlp`; masks `sshd`; configures a home firewall zone tuned for trusted networks. |

Each variant inherits the shared configuration under `Containerfiles/common/`, ensuring consistent editor defaults and tmux behavior across every image.

## Hardening defaults

* **Firewall** – Firewalld is enabled globally. The server image ships a restrictive `public` zone that only exposes SSH and Cockpit and blocks ping. The personal image sets the default zone to `home`, allowing only mDNS, SSH, and the Tailscale UDP port by default.
* **Updates** – `bootc-fetch-apply-updates.timer` is enabled on every image for unattended updates.
* **Access control** – `tailscaled` stays disabled on the base and server builds, but is enabled for the personal image. SSH is enabled only on the server variant and explicitly masked on the personal variant. The server image also enables `fail2ban` with an aggressive SSH jail.
* **Systemd lockdown (server)** – Server builds include a manager drop-in that locks personalities, restricts namespaces, protects kernel modules, and restricts setuid binaries by default.

## Local build and verification

1. Install Podman (or your preferred container engine) with sufficient privileges to run `dnf5` inside build containers.
2. Lint the Containerfiles:
   ```bash
   sudo ./scripts/lint.sh
   ```
3. Build-test all variants locally:
   ```bash
   sudo ./scripts/test.sh
   ```

Both scripts accept the `CONTAINER_ENGINE` environment variable if you prefer `buildah` or another compatible tool.

## Continuous integration and delivery

* **CI (`.github/workflows/ci.yml`)** runs on every pull request to `main`. It executes `actionlint`, lint checks the Containerfiles with Hadolint, and then runs `scripts/test.sh` under Podman to make sure each `dnf5`-based build still succeeds.
* **Release (`.github/workflows/release.yml`)** triggers only on merges to `main`. It rebuilds the three images, tags them as `ghcr.io/<owner>/bootc-base:<variant>`, and pushes them to GitHub Container Registry.

Configure the following repository secrets before merging to `main`:

* `GHCR_USERNAME` – GitHub username or organization that will own the images.
* `GHCR_TOKEN` – A fine-grained personal access token with `write:packages` scope.

## Suggested next steps

* Populate server-specific tooling such as metrics exporters, log shippers, or security agents once target workloads are defined.
* Add variant-specific Tailscale ACL configuration or device enrollment scripts as you move from the base images to device-specific builds.
* Consider integrating compliance scanning (for example, `oscap` using the bundled SCAP content) into CI to continuously validate hardening goals.
