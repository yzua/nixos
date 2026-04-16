# NixOS modules aggregation.

{
  imports = [
    # Core system
    ./bootloader.nix # Bootloader, kernel, systemd-boot
    ./nix.nix # Nix package manager, flakes, binary caches
    ./users.nix # User accounts and group memberships
    ./timezone.nix # Timezone (UTC+3)
    ./i18n.nix # Locale, input methods, keyboard layout
    ./environment.nix # Session variables and XDG paths
    ./kernel-tuning.nix # Kernel and network sysctl tuning (TCP BBR, inotify, memory)
    ./system-services.nix # SSD trim, earlyoom OOM protection, notification bus
    ./resource-limits.nix # Systemd timeouts, PAM session limits
    ./host-defaults.nix # Profile-based defaults for mySystem options
    ./host-info.nix # Hostname and state version management
    ./validation.nix # Cross-module conflict assertions

    # Hardware
    ./nvidia.nix # NVIDIA GPU drivers, CUDA, Wayland
    ./audio.nix # PipeWire audio stack
    ./bluetooth.nix # Bluetooth with Blueman
    ./libinput.nix # Touchpad and mouse input
    ./upower.nix # Battery and power monitoring
    ./fwupd.nix # Firmware updates (fwupd/LVFS)

    # Desktop environment
    ./niri.nix # Niri scrollable tiling Wayland compositor
    ./greetd.nix # greetd display manager with tuigreet
    ./xserver.nix # X server for XWayland compatibility
    ./xdg-desktop-portal.nix # XDG portals for Wayland
    ./nautilus.nix # GNOME Files with thumbnails and automounting

    # Networking
    ./networking.nix # NetworkManager with MAC randomization
    ./dnscrypt-proxy.nix # Encrypted DNS (DoH/DoT, DNSSEC)
    ./mullvad-vpn.nix # Mullvad VPN with hardened tunnel
    ./tor.nix # Tor SOCKS proxy and onion routing
    ./yggdrasil.nix # Yggdrasil encrypted mesh overlay network
    ./i2pd.nix # I2PD anonymous network router

    # Security
    ./security # Kernel hardening, firewall, AppArmor, opsec
    ./opensnitch.nix # Application firewall with network logging
    ./secure-boot.nix # Secure Boot preparation with sbctl
    ./sops.nix # SOPS-Nix encrypted secrets (age)

    # Applications
    ./browser-deps.nix # Chromium, Puppeteer dependencies
    ./flatpak.nix # Flatpak with Flathub
    ./gaming.nix # Steam, Lutris, Wine, MangoHud
    ./printing.nix # CUPS printing services
    ./android.nix # ADB and Fastboot support
    ./web-re.nix # Web reverse engineering and security tools
    ./kdeconnect.nix # KDE Connect phone-desktop integration
    ./vnc.nix # VNC remote access (x11vnc, noVNC, websockify)

    # Virtualisation
    ./virtualisation.nix # Docker and libvirt/QEMU
    ./waydroid.nix # Waydroid Android emulation
    ./nix-ld.nix # Dynamic linker for non-Nix binaries

    # Notifications
    ./ntfy.nix # Alertmanager → ntfy.sh push notifications

    # Monitoring and observability
    ./monitoring.nix # Sensors, vnStat, bandwhich
    ./netdata.nix # Real-time system monitoring dashboard
    ./scrutiny.nix # SMART disk health monitoring
    ./glance # Self-hosted dashboard
    ./loki.nix # Loki log aggregation with Promtail
    ./prometheus-grafana # Prometheus + Alertmanager + Grafana observability
    ./system-report.nix # Unified system health reporting

    # Boot optimization
    ./boot-optimization.nix # Defer monitoring services from blocking boot

    # Maintenance
    ./cleanup # Automated cleanup timers
    ./backup.nix # Restic backups with retention
    ./nh.nix # Nix Helper build tool
  ];
}
