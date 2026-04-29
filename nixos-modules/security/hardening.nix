# Kernel and system security hardening (sysctl, PAM, AppArmor, hidepid, coredump).

{
  imports = [
    ./_hardening-kernel.nix # Kernel params, sysctl tuning, module blacklisting
    ./_hardening-userspace.nix # AppArmor, sudo audit, /proc hidepid, coredump suppression
  ];
}
