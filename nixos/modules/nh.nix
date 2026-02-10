# Nix Helper (nh) build tool wrapper.
{ pkgs, user, ... }:

{
  environment = {
    systemPackages = with pkgs; [ nh ];
    sessionVariables.NH_FLAKE = "/home/${user}/System";
  };

  systemd.tmpfiles.rules = [ "d /var/cache/nh 0755 root root -" ];
}
