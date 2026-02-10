# ThinkPad power management and kernel modules.
_:

{
  powerManagement.enable = true;

  services = {
    power-profiles-daemon.enable = false; # Conflicts with TLP
  };

  boot.kernelModules = [
    "acpi_call"
    "thinkpad_acpi"
    "tp_smapi"
  ];
}
