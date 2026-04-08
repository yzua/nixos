# PC host-specific tuning (NVIDIA, IO, filesystem).

_: {
  # Better TTY console resolution and smoother VT switching on NVIDIA Wayland
  boot.kernelParams = [ "nvidia_drm.fbdev=1" ];

  # Use an SSD-friendly scheduler on flash storage and keep BFQ for rotational disks.
  # Force SATA links to maximum performance on this host to avoid ALPM/DIPM-related
  # freezes on the root SSD path under sustained write load.
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
    ACTION=="add|change", SUBSYSTEM=="scsi_host", KERNEL=="host*", ATTR{link_power_management_policy}="max_performance"
  '';
}
