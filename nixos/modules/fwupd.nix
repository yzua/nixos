# Firmware update daemon (fwupd/LVFS) for BIOS and device firmware updates.
{
  config,
  lib,
  ...
}:

{
  options.mySystem.fwupd = {
    enable = lib.mkEnableOption "firmware update daemon (fwupd/LVFS)";
  };

  config = lib.mkIf config.mySystem.fwupd.enable {
    services.fwupd.enable = true;
  };
}
