# bootc-base

This repository defines a hardened Fedora 42 bootc base and two opinionated variants that I use to seed new systems.

* `Containerfile.base` lays down the common foundation: Nano is replaced with Vim, `tmux` is pre-configured with mouse support, Firewalld is enabled by default, and the bootc update timer is activated so the systems stay current.
* `Containerfile.server` layers on remote-access and auditing defaults suitable for servers. It enables SSH, deploys Fail2ban in an aggressive mode, and locks systemd down with a restrictive capability set while applying a drop-target firewall zone that only exposes SSH.
* `Containerfile.personal` targets laptops and desktops. SSH is masked, Tailscale starts on boot, TLP and Powertop provide baseline power management, and a LAN-friendly firewall zone keeps mDNS/printing discoverable without opening the system more broadly.

All Containerfiles share a `files/` tree that provides configuration snippets (Vim defaults, tmux configuration, journald retention, firewall zones, etc.).

## Local development

Requirements:

* Fedora 42 or newer (or any host with a recent Podman installation)
* Network access to pull `quay.io/fedora/fedora-bootc:42`

The helper scripts expect Podman. Install Podman and enable user namespaces if required by your distro.

Run linting:

```bash
sudo bash scripts/lint.sh
```

Run the test builds (this builds the base image and both variants locally):

```bash
sudo bash scripts/test.sh
```

Both scripts mount the repository read-only when possible, so SELinux enforcing hosts should run them with `sudo` to avoid labeling errors.

## CI/CD

GitHub Actions enforces the same scripts:

* `CI` runs on every pull request targeting `main`, installing Podman on the GitHub runner and executing `scripts/lint.sh` and `scripts/test.sh`.
* `Release Images` triggers on pushes to `main` (and can be invoked manually). It builds the base image plus the server and personal variants, then pushes them to GHCR under `ghcr.io/<owner>/bootc-base`, `ghcr.io/<owner>/bootc-server`, and `ghcr.io/<owner>/bootc-personal`.

Only the merge workflow publishes images; pull requests never push registry artifacts.

## Image usage

Each published image ships with the bootc metadata required for `bootc install` or `bootc upgrade`. Example usage:

```bash
bootc install ghcr.io/<owner>/bootc-server:latest
```

The server and personal variants expect you to enrol devices into Tailscale manually. For SSH on the personal variant, drop a file at `/etc/ssh/enable-sshd` before first boot or unmask the service after install.

## Next steps

* Integrate compliance scanning (OpenSCAP or `oscap`) as a follow-up workflow.
* Extend variant-specific package sets for real workloads (observability stacks for servers, development kits for personal machines).
* Automate Tailscale enrolment via tagged secrets or one-time auth keys stored in your secrets manager.
