# PC host-specific tuning (NVIDIA, IO, filesystem).
_: {
  # Better TTY console resolution and smoother VT switching on NVIDIA Wayland
  boot.kernelParams = [ "nvidia_drm.fbdev=1" ];

  # BFQ IO scheduler for SATA SSDs (better fairness for desktop multitasking)
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/scheduler}="bfq"
  '';
}
