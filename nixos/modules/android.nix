# Android device support (ADB, Fastboot, udev rules).
{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.android-tools ];

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0660", GROUP="users"
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ENV{ID_MM_DEVICE_IGNORE}="1"
  '';
}
