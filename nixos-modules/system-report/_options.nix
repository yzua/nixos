# System report option definitions.

{ lib, optionHelpers, ... }:

let
  inherit (optionHelpers)
    mkStrOption
    mkIntOption
    ;
in
{
  options.mySystem.systemReport = {
    enable = lib.mkEnableOption "unified system health reporting";
    outputDir = mkStrOption "/var/lib/system-report" "Directory for report output.";
    retentionDays = mkIntOption 30 "Days to keep historical reports.";
  };
}
