# Laptop: power management, NVIDIA Optimus, WiFi, bluetooth.
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./local-packages.nix
    ../../nixos/modules
    ./modules
  ];

  # Host identity managed by nixos/modules/host-info.nix
  mySystem = {
    hostInfo.enable = true;
    hostProfile = "laptop";
    observability.enable = false; # Save ~150MB RAM — no dashboards/alerts justify it on laptop
  };

  services.avahi.allowInterfaces = [ "wlp0s20f3" ];
}
