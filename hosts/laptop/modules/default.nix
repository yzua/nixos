# ThinkPad host-specific modules.
{
  imports = [
    ./boot.nix # Kernel params (acpi_backlight)
    ./nvidia.nix # NVIDIA Optimus hybrid graphics
    ./power.nix # Power management and kernel modules
    ./tlp.nix # TLP battery and CPU governor
    ./thermal.nix # Intel thermald for DPTF thermal management
  ];
}
