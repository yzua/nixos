# Laptop: power management, NVIDIA Optimus, WiFi, bluetooth.
{ stateVersion, hostname, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./local-packages.nix
    ../../nixos/modules
    ./modules
  ];

  networking.hostName = hostname;
  system = { inherit stateVersion; };

  mySystem = {
    hostProfile = "laptop";
    observability.enable = false; # Save ~150MB RAM — no dashboards/alerts justify it on laptop
  };

  services.avahi.allowInterfaces = [ "wlp0s20f3" ];
}
