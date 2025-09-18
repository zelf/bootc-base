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
```

## Git Commit Guidelines

Follow the “How to Write a Git Commit Message” rules by cbeams.

1. Separate subject from body with a blank line.
2. Limit subject line to **50 characters**.
3. Capitalize the subject line.
4. Do *not* end subject line with a period.  
5. Use the imperative mood in subject line (e.g. “Add”, “Remove”, “Fix”).  
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
