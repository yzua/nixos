# Operational security (kexec, metadata stripping, zram, NTS time).
{ lib, pkgs, ... }:

{
  boot.kernel.sysctl = {
    "kernel.kexec_load_disabled" = 1; # Prevent runtime kernel replacement
  };

  environment.systemPackages = with pkgs; [
    mat2 # Metadata removal (images, PDFs, office docs)
    exiftool
  ];

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
        server time.cloudflare.com iburst nts
        server virginia.time.system.gov iburst nts
        makestep 1.0 3
      '';
    };
  };
}
