# Laptop: power management, NVIDIA Optimus, WiFi, bluetooth.

{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./local-packages.nix
    ../../nixos-modules
    ./modules
  ];

  mySystem = {
    hostProfile = "laptop";
    observability.enable = false; # Save ~150MB RAM — no dashboards/alerts justify it on laptop
    ntfy.enable = false; # Requires observability/Alertmanager integration.
  };

  services.avahi.allowInterfaces = [ "wlp0s20f3" ];
}
