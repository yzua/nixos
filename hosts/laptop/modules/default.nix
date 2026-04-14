# ThinkPad host-specific modules.

{
  imports = [
    ./boot.nix # Kernel params (acpi_backlight)
    ./nvidia.nix # NVIDIA Optimus hybrid graphics
    ./tlp.nix # TLP battery, CPU governor, power management, ThinkPad kernel modules
    ./thermal.nix # Intel thermald for DPTF thermal management
  ];
}
