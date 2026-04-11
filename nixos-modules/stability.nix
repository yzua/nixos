# System stability, resource limits, and high-performance networking tuning.

{ lib, ... }:

{
  services = {
    fstrim = {
      enable = true;
      interval = "weekly";
    };

    earlyoom = {
      enable = true;
      freeMemThreshold = 8; # 8% ≈ 2.6GB on 32GB (was 5%)
      freeSwapThreshold = 10;
      enableNotifications = true; # Desktop notification on kill
    };

    # Resolve conflict: earlyoom sets systembus-notify=true, smartd (via Scrutiny) sets false.
    # We want notifications enabled for earlyoom OOM-kill alerts.
    systembus-notify.enable = lib.mkForce true;

    # Journald limits -- Loki/Promtail retains 30 days, so keep journal lean
    journald.extraConfig = ''
      SystemMaxUse=500M
      SystemMaxFileSize=50M
      MaxRetentionSec=7day
      ForwardToSyslog=no
      Compress=yes
    '';
  };

  boot.kernelModules = [ "tcp_bbr" ]; # BBR congestion control module

  boot.kernel.sysctl = {
    # Inotify limits for development (VS Code, webpack, rust-analyzer file watchers)
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 1024;

    "fs.file-max" = 1000000;
    "net.core.somaxconn" = 65536;
    "net.core.netdev_max_backlog" = 250000;
    "net.ipv4.tcp_max_syn_backlog" = 65536;
    "net.ipv4.ip_local_port_range" = "1024\t65535";
    "kernel.pid_max" = 4194303;
    "net.ipv4.tcp_fin_timeout" = 15;

    # TCP buffer tuning
    "net.core.rmem_max" = 16777216; # 16 MB
    "net.core.wmem_max" = 16777216; # 16 MB
    "net.ipv4.tcp_rmem" = "4096\t87380\t16777216";
    "net.ipv4.tcp_wmem" = "4096\t65536\t16777216";

    # Memory management
    "vm.swappiness" = 10;
    # Dirty ratios tuned for DRAM-less SSD + LUKS — flush writes sooner in smaller
    # bursts to avoid saturating the device. Default dirty_ratio=20 causes multi-second
    # stalls when the SSD's SLC cache fills and writes drop to native TLC speed.
    "vm.dirty_ratio" = 5; # Max 5% of RAM dirty before blocking writes
    "vm.dirty_background_ratio" = 1; # Start background writeback at 1%
    "vm.dirty_writeback_centisecs" = 300; # Flush every 3 seconds (default 500 = 5s)
    "vm.dirty_expire_centisecs" = 1500; # Expire dirty pages after 15s (default 3000)
    "vm.vfs_cache_pressure" = 50; # Keep dentries/inodes longer (good for dev work with large codebases)

    # TCP optimizations
    "net.ipv4.tcp_fastopen" = 3; # Client+server TFO (saves 1 RTT on HTTPS connections)
    "net.ipv4.tcp_mtu_probing" = 1; # Discover path MTU (helps on VPN tunnels like Mullvad)

    # TCP BBR congestion control -- 10-30% throughput improvement on VPN connections
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };

  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "30s";
    # Avoid greetd/user@ login loops when user manager startup is heavy on cold boot.
    DefaultTimeoutStartSec = "180s";
    DefaultDeviceTimeoutSec = "30s";
    DefaultLimitNOFILE = 200000;
    DefaultLimitNPROC = 65536;
    # Disable hardware watchdog arming on reboot/shutdown to prevent
    # "watchdog0: watchdog did not stop!" and unnecessary 10-minute fallback timer.
    RuntimeWatchdogSec = "0";
    RebootWatchdogSec = "0";
    KExecWatchdogSec = "0";
  };

  # Keep user-session app scopes from delaying reboot for the default 90s.
  systemd.user.extraConfig = ''
    DefaultTimeoutStopSec=30s
  '';

  # PAM session limits (consolidated — includes core dump disable from security/hardening.nix)
  security.pam.loginLimits = [
    {
      domain = "*";
      type = "hard";
      item = "core";
      value = "0"; # Disable core dumps (security hardening)
    }
    {
      domain = "*";
      type = "-";
      item = "nofile";
      value = 200000;
    }
    {
      domain = "*";
      type = "-";
      item = "nproc";
      value = 65536;
    }
    {
      domain = "*";
      type = "-";
      item = "stack";
      value = "65536"; # 64 MB
    }
  ];
}
