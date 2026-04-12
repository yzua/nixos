# System performance services: SSD trimming, OOM protection, notification bus.

{ lib, ... }:

{
  services = {
    fstrim = {
      enable = true;
      interval = "weekly";
    };

    earlyoom = {
      enable = true;
      freeMemThreshold = 8; # 8% ≈ 2.6GB on 32GB (was 5%)
      freeSwapThreshold = 10;
      enableNotifications = true; # Desktop notification on kill
    };

    # Resolve conflict: earlyoom sets systembus-notify=true, smartd (via Scrutiny) sets false.
    # We want notifications enabled for earlyoom OOM-kill alerts.
    systembus-notify.enable = lib.mkForce true;
  };
}
