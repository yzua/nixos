# System maintenance services: SSD trimming, OOM protection (earlyoom), notification bus.

{ lib, ... }:

{
  services = {
    fstrim = {
      enable = true;
      interval = "weekly";
    };

    earlyoom = {
      enable = true;
      freeMemThreshold = 15; # 15% ≈ 4.8GB on 32GB — act earlier to prevent compositor stalls
      freeSwapThreshold = 15;
      enableNotifications = true; # Desktop notification on kill
    };

    # Resolve conflict: earlyoom sets systembus-notify=true, smartd (via Scrutiny) sets false.
    # We want notifications enabled for earlyoom OOM-kill alerts.
    systembus-notify.enable = lib.mkForce true;
  };
}
