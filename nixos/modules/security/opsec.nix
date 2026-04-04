# Operational security (kexec, metadata stripping, zram, NTS time).

{ lib, ... }:

{
  boot.kernel.sysctl = {
    "kernel.kexec_load_disabled" = 1; # Prevent runtime kernel replacement
  };

  # RAM-only swap — prevents sensitive data leaking to unencrypted partitions
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # Chrony with NTS (authenticated time) replaces systemd-timesyncd
  services = {
    timesyncd.enable = lib.mkForce false;
    chrony = {
      enable = true;
      servers = [ ]; # NTS sources below instead of plain NTP
      extraConfig = ''
        server virginia.time.system.gov iburst nts
        server time.nist.gov iburst nts
        server nts.netnod.se iburst nts
        makestep 1.0 3
      '';
    };
  };
}
