# Pear Desktop declarative theme + plugin baseline.
{
  lib,
  pkgs,
  ...
}:
let
  pearConfigPatch = pkgs.writeText "pear-config-patch.json" (
    builtins.toJSON {
      options = {
        autoUpdates = false; # Nix manages updates
        restartOnConfigChanges = false;
      };
      plugins = {
        "disable-autoplay" = {
          enabled = false;
        };
        "playback-speed" = {
          enabled = true;
        };
        "precise-volume" = {
          enabled = true;
        };
        "skip-disliked-songs" = {
          enabled = true;
        };
        sponsorblock = {
          enabled = true;
        };
        "synced-lyrics" = {
          enabled = true;
        };
      };
    }
  );
in
{
  xdg.configFile."YouTube Music/themes/gruvbox-soft.css".source = ../../../themes/gruvbox-ytmusic.css;

  # Keep config writable for Pear while enforcing declarative baseline at switch time.
  home.activation.pearDesktopConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    CONFIG_DIR="$HOME/.config/YouTube Music"
    CONFIG_FILE="$CONFIG_DIR/config.json"
    THEME_PATH="$HOME/.config/YouTube Music/themes/gruvbox-soft.css"

    mkdir -p "$CONFIG_DIR"

    if [ -L "$CONFIG_FILE" ]; then
      rm "$CONFIG_FILE"
    fi

    if [[ ! -f "$CONFIG_FILE" ]] || ! ${pkgs.jq}/bin/jq empty "$CONFIG_FILE" >/dev/null 2>&1; then
      printf '{}\n' > "$CONFIG_FILE"
    fi

    ${pkgs.jq}/bin/jq --arg theme "$THEME_PATH" -s '(.[0] * .[1]) | .options.themes = [$theme]' "$CONFIG_FILE" "${pearConfigPatch}" > "$CONFIG_FILE.tmp"
    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    chmod 644 "$CONFIG_FILE"
  '';
}
