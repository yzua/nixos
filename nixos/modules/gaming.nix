# Gaming support (Steam, Lutris, Wine, MangoHud).
{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.mySystem.gaming = {
    enable = lib.mkEnableOption "gaming support with Steam and related tools";

    enableGamescope = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = "Enable gamescope session for Steam. Provides compositor session with better frame timing, VRR support, and upscaling.";
    };
  };

  config = lib.mkIf config.mySystem.gaming.enable {
    programs.steam = {
      enable = true;
      gamescopeSession.enable = config.mySystem.gaming.enableGamescope;
      extraCompatPackages = with pkgs; [ proton-ge-bin ];
    };

    environment = {
      sessionVariables = {
        STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
      };

      systemPackages = with pkgs; [
        mangohud
        protonup-ng
        lutris
        steam-run
        wine
        winetricks
        libunwind
      ];
    };
  };
}
