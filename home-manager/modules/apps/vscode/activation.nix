# VS Code activation script (writes mutable settings.json).
{
  lib,
  pkgs,
  constants,
  ...
}:

let
  settings = import ./_settings.nix { inherit constants pkgs; };
  settingsJson = builtins.toJSON settings;
in
{
  # Settings managed via activation script (writable file, not nix store symlink).
  # Extensions can modify settings at runtime; `just home` resets to baseline.
  home.activation.vscodeWritableSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SETTINGS_DIR="$HOME/.config/Code/User"
    SETTINGS_FILE="$SETTINGS_DIR/settings.json"

    mkdir -p "$SETTINGS_DIR"

    if [ -L "$SETTINGS_FILE" ]; then
      rm "$SETTINGS_FILE"
    fi

    cp ${pkgs.writeText "vscode-settings.json" settingsJson} "$SETTINGS_FILE"
    chmod 644 "$SETTINGS_FILE"
  '';
}
