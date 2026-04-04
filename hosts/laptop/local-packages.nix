# Local system packages for the 'laptop' host.

{ pkgsStable, ... }:
{
  environment.systemPackages = with pkgsStable; [
    acpi
    powertop
    tpacpi-bat
  ];
}
