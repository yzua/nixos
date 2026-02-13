# ThinkPad kernel params for backlight and NVIDIA framebuffer.
_:

{
  boot.kernelParams = [
    "acpi_backlight=native" # Required for thinkpad_acpi backlight save/load
    "nvidia_drm.fbdev=1" # Framebuffer device emulation (better console resolution, VT switching)
  ];
}
