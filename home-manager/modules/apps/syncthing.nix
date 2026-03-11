# Syncthing decentralized file sync.
{
  lib,
  ...
}:

{
  services.syncthing = {
    enable = true;

    tray = {
      enable = true;
      command = "syncthingtray --wait";
    };
  };

  home.activation.syncthingTrayTimeouts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SYNC_TRAY_CONFIG="$HOME/.config/syncthingtray.ini"

    set_or_append_ini_key() {
      local key="$1"
      local value="$2"
      local line="''${key}=''${value}"
      local tmp
      local existing
      local replaced=0

      tmp="$(mktemp)"

      while IFS= read -r existing || [ -n "$existing" ]; do
        if [[ "$existing" == "''${key}="* ]]; then
          printf '%s\n' "''${line}" >> "$tmp"
          replaced=1
        else
          printf '%s\n' "$existing" >> "$tmp"
        fi
      done < "$SYNC_TRAY_CONFIG"

      if [[ "$replaced" -eq 0 ]]; then
        printf '%s\n' "''${line}" >> "$tmp"
      fi

      mv "$tmp" "$SYNC_TRAY_CONFIG"
    }

    if [ -f "$SYNC_TRAY_CONFIG" ]; then
      set_or_append_ini_key $'connections\\1\\longPollingTimeout' '30000'
      set_or_append_ini_key $'connections\\1\\requestTimeout' '15000'
    fi
  '';
}
