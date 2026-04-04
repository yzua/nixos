# PC host-specific tuning (NVIDIA, IO, filesystem).

_: {
  # Better TTY console resolution and smoother VT switching on NVIDIA Wayland
  boot.kernelParams = [ "nvidia_drm.fbdev=1" ];

  # Use an SSD-friendly scheduler on flash storage and keep BFQ for rotational disks.
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
  '';
}
