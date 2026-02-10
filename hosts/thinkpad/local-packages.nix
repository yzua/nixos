# Local system packages for the 'thinkpad' host.
{ pkgs, pkgsStable, ... }:
{
  environment.systemPackages =
    (with pkgs; [
      tlp
    ])
    ++ (with pkgsStable; [
      acpi
      powertop
      tpacpi-bat
    ]);
}
