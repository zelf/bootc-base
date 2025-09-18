# Bootc Image Agent Specification

## Base

- **Distro:** Fedora 42 (container base)
- **Image type:** OCI container
- **Registry:** `zelf/bootc-base`
- **Update policy:** Automatic via bootc + quadlet units
- **Rollback:** Supported by bootc mechanism
- **User:** `zelf`
- **SSH keys:** placeholder
- **Partitioning:** custom hardened layout (to be detailed)

---

## Common Base (all variants)

### Packages
- Remove:
- Add:  
  - `vim-enhanced`
  - `tmux` (mouse enabled by default config)
  - `tailscale`
  - `firewalld`
- Swap: `nano-default-editor` `vim-default-editor`

### Services
- `firewalld` enabled and active
- `tailscaled` disabled by default (enabled in specific variants if required)
- Automatic updates: `bootc-fetch-apply-updates.timer` enabled

---

## Variant: Server Base

### Additional Packages
- `<server-specific tools>` (to be defined, e.g. podman, fail2ban, monitoring agents)

### Services
- `sshd` enabled
- Logging + auditing enhancements

### Hardening
- SELinux enforcing
- Systemd lockdown configuration (to be detailed)
- Strict firewall rules

---

## Variant: Personal Device Base

### Additional Packages
- `<desktop or user apps>` (to be defined, e.g. GNOME, browsers, dev tools)

### Services
- `sshd` disabled by default
- `tailscaled` enabled for device connectivity
- Firewall relaxed for local network use

### Hardening
- SELinux enforcing
- Device-level encryption hooks (manual setup during install)

---

## Partition Layout (Hardened)

> Manual install will enforce hardened scheme.
- `/boot` separate
- `/var` separate
- `/home` separate (encrypted recommended)
- `/` minimal
- `tmpfs` for `/tmp`

---

## Build and Publish Flow

### Build
```bash
podman build -t <registry>/<namespace>/bootc:base -f Containerfile.base
podman build -t <registry>/<namespace>/bootc:server -f Containerfile.server
podman build -t <registry>/<namespace>/bootc:personal -f Containerfile.personal
