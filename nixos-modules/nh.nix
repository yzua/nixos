# Nix Helper (nh) build tool wrapper.

{
  constants,
  pkgsStable,
  user,
  ...
}:

{
  environment = {
    systemPackages = with pkgsStable; [ nh ];
    sessionVariables.NH_FLAKE = "/home/${user}/${constants.paths.systemRepo}";
  };

  systemd.tmpfiles.rules = [ "d /var/cache/nh 0755 root root -" ];
}
