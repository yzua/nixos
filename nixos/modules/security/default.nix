# System security hardening modules.

{
  imports = [
    ./aide.nix # AIDE file integrity monitoring (weekly)
    ./audit-logging.nix # Security event logging with fail2ban
    ./audit.nix # Security audit timer and service
    ./firewall.nix # Network firewall configuration
    ./hardening.nix # Kernel and system hardening (sysctl, PAM, AppArmor, hidepid, coredump)
    ./opsec.nix # Operational security (MAC, kexec, metadata, zram, NTS, Thunderbolt)
    ./services.nix # Security-related services (Avahi, dbus, audit)
  ];
}
