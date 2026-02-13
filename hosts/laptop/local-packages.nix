# Local system packages for the 'laptop' host.
{ pkgs, pkgsStable, ... }:
{
  environment.systemPackages =
    (with pkgs; [
      # tlp provided by services.tlp
    ])
    ++ (with pkgsStable; [
      acpi
      powertop
      tpacpi-bat
    ]);
}
