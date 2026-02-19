# System Security Hardening

7 always-on sub-modules (no enable guard — security is unconditional). Split from monolithic `security.nix` for maintainability. Only exception: `audit-logging.nix` is guarded by `mySystem.auditLogging.enable`.

Parent modules (`sandboxing.nix`, `opensnitch.nix`, `sops.nix`, `tor.nix`) handle togglable security features outside this directory.

---

## Module Map

| File | Purpose | Guarded? |
|------|---------|----------|
| `hardening.nix` | Kernel sysctl, AppArmor, PAM core dumps, sudo, hidepid=2, coredump | Always-on |
| `firewall.nix` | nftables firewall, LLMNR/NetBIOS/SMB hostname leak prevention | Always-on |
| `services.nix` | dbus-broker, Avahi (explicit `allowInterfaces`), systemd Manager timeouts | Always-on |
| `audit.nix` | Weekly Lynis security audit timer + service | Always-on |
| `audit-logging.nix` | fail2ban intrusion prevention (5 retries, 1h ban, exponential backoff) | `mySystem.auditLogging.enable` |
| `opsec.nix` | MAC randomization, kexec disable, metadata removal (mat2, exiftool), zram swap, Chrony NTS, Thunderbolt | Always-on |
| `aide.nix` | AIDE file integrity monitoring (weekly scan) | Always-on |

---

## Key Hardening Values (`hardening.nix`)

| sysctl | Value | Rationale |
|--------|-------|-----------|
| `kernel.kptr_restrict` | 2 | Hide kernel pointers from all users |
| `kernel.dmesg_restrict` | 1 | Restrict dmesg to privileged users |
| `kernel.yama.ptrace_scope` | 1 | Restrict ptrace to parent-child |
| `net.core.bpf_jit_harden` | 2 | Harden BPF JIT compiler |
| `net.ipv4.tcp_timestamps` | 0 | Disable TCP timestamps (privacy) |
| `net.ipv4.conf.all.rp_filter` | 2 | Loose reverse path filtering (Docker/Mullvad compat) |
| `kernel.unprivileged_bpf_disabled` | 1 | Restrict unprivileged BPF |

**Blacklisted kernel modules**: dccp, sctp, rds, tipc, firewire-*, thunderbolt, vivid, cramfs, hfs, hfsplus, udf

**Disabled (documented why)**:
- `graphene-hardened` kernel — crashes glycin/bwrap image loaders (Loupe, Nautilus thumbnails)
- `auditd` — AppArmor + auditd kernel interaction causes audit_log_subj_ctx panics

---

## Conventions

- Section headers use `# === Section Name ===` for visual structure
- Non-default security values get inline comments explaining rationale
- `mkForce` used only for security hardening overrides (e.g., IPv6 privacy extensions)
- Avahi **must** have explicit `allowInterfaces` (validated in `validation.nix`)

---

## Adding a Security Rule

1. Identify the right sub-module (sysctl → `hardening.nix`, network → `firewall.nix`, service → `services.nix`)
2. Add the rule with inline comment explaining rationale
3. If rule conflicts with other modules, add assertion to `../validation.nix`
4. Document non-default values inline
5. Run: `just modules && just lint && just format && just check && just nixos`

## Modifying Hardening

- **Loosening** a value: Document why (e.g., Docker compat for `rp_filter = 2`)
- **Adding** a value: Include threat model rationale
- **Blacklisting** a module: Add to `boot.blacklistedKernelModules` in `hardening.nix`
