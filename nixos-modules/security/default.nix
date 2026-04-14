# System security hardening modules.

{
  imports = [
    ./aide.nix # AIDE file integrity monitoring (weekly)
    ./fail2ban.nix # Intrusion prevention with fail2ban
    ./lynis.nix # Weekly Lynis security audit
    ./firewall.nix # Network firewall configuration
    ./hardening.nix # Kernel and system hardening (sysctl, PAM, AppArmor, hidepid, coredump)
    ./metadata-scrubber.nix # Automatic metadata scrubbing for user files
    ./opsec.nix # Operational security (MAC, kexec, metadata, zram, NTS, Thunderbolt)
    ./services.nix # Security-related services (Avahi, dbus, audit)
  ];
}
