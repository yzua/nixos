# Kernel-level hardening: boot parameters, sysctl tuning, and module blacklisting.

_:

{
  boot = {
    kernelParams = [
      # === Kernel Memory Hardening ===
      "page_alloc.shuffle=1" # ASLR for page allocator
      "randomize_kstack_offset=on" # Randomize kernel stack offset per syscall
      "vsyscall=none" # Disable legacy vsyscall (attack surface reduction)
      "slab_nomerge" # Prevent slab cache merging (stops heap exploitation)
      "init_on_alloc=1" # Zero memory on allocation (prevents info leaks)
      "init_on_free=1" # Zero memory on free (prevents use-after-free data)
      "module.sig_enforce=1" # Only load signed kernel modules
      "lockdown=confidentiality" # Kernel lockdown: restrict /dev/mem, kexec, etc.
      "loglevel=4" # Restrict access to kernel logs

      # === Suspend Hardening ===
      "mem_sleep_default=deep" # Prefer deep sleep (full S3) over s2idle

      # === RNG Hardening ===
      "random.trust_cpu=off" # Don't trust CPU RNG (RDRAND) — use entropy pool
    ];

    blacklistedKernelModules = [
      # Obscure network protocols (common exploit targets)
      "dccp"
      "sctp"
      "rds"
      "tipc"
      # FireWire/Thunderbolt (DMA attack vectors)
      "firewire-core"
      "firewire-ohci"
      "firewire-sbp2"
      "thunderbolt"
      # Virtual device attack surface
      "vivid" # Virtual video test driver (kernel attack surface)
      # Obscure filesystems
      "cramfs"
      "hfs"
      "hfsplus"
      "udf"
    ];

    kernel.sysctl = {
      # === Network Security ===
      "net.ipv4.tcp_syncookies" = 1; # SYN flood protection
      "net.ipv4.conf.all.rp_filter" = 2; # Loose mode — strict (1) breaks Docker/Mullvad routing
      "net.ipv4.conf.default.rp_filter" = 2;
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1; # Smurf attack prevention
      "net.ipv4.icmp_ignore_bogus_error_responses" = 1;

      # Disable ICMP redirects (MITM prevention)
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.secure_redirects" = 0;
      "net.ipv4.conf.default.secure_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;

      # Disable source routing (IP spoofing prevention)
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv4.conf.default.accept_source_route" = 0;
      "net.ipv6.conf.all.accept_source_route" = 0;
      "net.ipv6.conf.default.accept_source_route" = 0;

      "net.ipv4.conf.all.log_martians" = 1; # Log spoofed packets

      # === Kernel Protection ===
      "kernel.kexec_load_disabled" = 1; # Prevent runtime kernel replacement
      "kernel.kptr_restrict" = 2; # Hide kernel pointers
      "kernel.dmesg_restrict" = 1; # Root-only dmesg
      "kernel.yama.ptrace_scope" = 1; # Parent-only ptrace
      "kernel.unprivileged_bpf_disabled" = 1;
      "net.core.bpf_jit_harden" = 2;
      "kernel.core_pattern" = "|/bin/false";
      "kernel.sysrq" = 0; # Disable SysRq (physical attack vector)
      "fs.suid_dumpable" = 0;
      "fs.protected_fifos" = 2;
      "fs.protected_regular" = 2;
      "fs.protected_hardlinks" = 1; # Prevent hardlink-based privilege escalation
      "fs.protected_symlinks" = 1; # Prevent symlink-based privilege escalation

      # PRIVACY: Prevent remote uptime fingerprinting
      "net.ipv4.tcp_timestamps" = 0;
      "kernel.perf_event_paranoid" = 3; # Prevent side-channel attacks
      "kernel.perf_cpu_time_max_percent" = 1; # Limit perf overhead
      "kernel.perf_event_max_sample_rate" = 1; # Restrict sampling rate

      # Exploit surface reduction
      "kernel.io_uring_disabled" = 2; # Disable io_uring (frequent exploit target, rarely needed on desktop)
      "vm.unprivileged_userfaultfd" = 0; # Restrict userfaultfd (used in exploit chains)

      # === IPv6 Neighbor Discovery Hardening ===
      "net.ipv6.conf.all.accept_ra" = 0; # Don't accept router advertisements
      "net.ipv6.conf.default.accept_ra" = 0;

      # === Additional Kernel Hardening ===
      "kernel.ftrace_enabled" = 0; # Disable function tracing (exploit tooling uses this)
      # NOTE: TCP SACK/DACK/FACK were disabled for CVE-2019-11478 (kernel 5.x).
      # That CVE is patched in all kernels >= 5.2; this system runs 6.x.
      # Re-enabling avoids TCP throughput degradation over VPN/WireGuard links.

      # === Enhanced ASLR ===
      # Maximize address space randomization for 64-bit (28 bits = 256MB range)
      "vm.mmap_rnd_bits" = 28;
      "vm.mmap_rnd_compat_bits" = 8;
    };
  };
}
