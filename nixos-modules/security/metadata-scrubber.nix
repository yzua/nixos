# System-wide automatic metadata scrubbing.
# Provides mat2/exiftool/inotify-tools in system PATH for CLI use.
# User-level services (watcher, full scrub, timer) live in HM modules/apps/metadata-scrubber.nix.

{
  config,
  lib,
  pkgsStable,
  ...
}:

{
  options.mySystem.metadataScrubber = {
    enable = lib.mkEnableOption "automatic metadata scrubbing for user files";
  };

  config = lib.mkIf config.mySystem.metadataScrubber.enable {
    # inotifywait watches directories; mat2/exiftool do the actual stripping
    environment.systemPackages = [
      pkgsStable.inotify-tools
      pkgsStable.mat2
      pkgsStable.exiftool
    ];
  };
}
