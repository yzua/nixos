# Nix Helper (nh) build tool wrapper.
{ pkgsStable, user, ... }:

{
  environment = {
    systemPackages = with pkgsStable; [ nh ];
    sessionVariables.NH_FLAKE = "/home/${user}/System";
  };

  systemd.tmpfiles.rules = [ "d /var/cache/nh 0755 root root -" ];
}
