# Laptop: power management, NVIDIA Optimus, WiFi, bluetooth.
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./local-packages.nix
    ../common-host-info.nix
    ../../nixos/modules
    ./modules
  ];

  mySystem = {
    hostProfile = "laptop";
    observability.enable = false; # Save ~150MB RAM — no dashboards/alerts justify it on laptop
  };

  services.avahi.allowInterfaces = [ "wlp0s20f3" ];
}
