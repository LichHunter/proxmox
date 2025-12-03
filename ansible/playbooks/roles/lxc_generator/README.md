# LXC Generator Role

Fixes systemd credential issues in Debian 13 (Trixie) LXC containers running systemd 256+.

## Problem

Debian 13 ships with systemd 257, which introduced stricter credential handling. Services like `systemd-journald`, `systemd-sysctl`, and others use `ImportCredential=` directives that fail in unprivileged LXC containers, causing:

- Exit code 243 (CREDENTIALS)
- No system logs (journald failure)
- Failed system services

## Solution

This role installs the `lxc.generator` script from the [LXC distrobuilder project](https://github.com/lxc/distrobuilder), which:

- Detects LXC container environment
- Automatically clears `ImportCredential=` directives for systemd 256+
- Fixes other LXC-specific systemd compatibility issues
- Maintains security (no privileged mode or nesting required)

## Requirements

- Debian 13 (Trixie) or similar with systemd 256+
- Running inside an LXC container
- Internet connectivity to download the generator script

## Role Variables

Available variables are defined in `defaults/main.yaml`:

```yaml
# URL to download lxc.generator from
lxc_generator_url: "https://sources.debian.org/data/main/d/distrobuilder/3.2-2/distrobuilder/lxc.generator"

# Path where the generator will be installed
lxc_generator_path: "/etc/systemd/system-generators/lxc"

# Whether to automatically reboot after installation if services are failing
lxc_generator_auto_reboot: false

# Whether to restart failed services after daemon-reload
lxc_generator_restart_services: true
```

## Usage

### Include in Playbook

```yaml
- name: Configure my service
  hosts: my_lxc_container
  roles:
    - lxc_generator
    - my_other_roles
```

### With Custom Variables

```yaml
- name: Configure with auto-reboot
  hosts: my_lxc_container
  roles:
    - role: lxc_generator
      vars:
        lxc_generator_auto_reboot: true
```

### Standalone Playbook

```yaml
- name: Fix systemd credentials in LXC containers
  hosts: lxc
  become: false
  roles:
    - lxc_generator
```

## Behavior

The role will:

1. Detect if running in an LXC container
2. Check systemd version
3. Skip installation if not LXC or systemd < 256
4. Download and install lxc.generator script
5. Reload systemd daemon
6. Attempt to restart failed services (if enabled)
7. Optionally reboot the system (if `lxc_generator_auto_reboot: true`)

## Notes

- The generator creates files in `/run/systemd`, so changes don't persist if the rootfs moves
- A reboot is recommended after first installation for full effect
- The role is idempotent - safe to run multiple times
- No changes are made to systems that don't need it (non-LXC or older systemd)

## References

- [LXC distrobuilder project](https://github.com/lxc/distrobuilder)
- [Proxmox forum discussion](https://forum.proxmox.com/threads/systemd-creds-errors-in-debian-13-lxc-containers.171706/)
- [Debian systemd credentials fix guide](https://diymediaserver.com/post/upgrade-debian-12-to-13-proxmox-lxc-243-credentials-fix/)
