# Noctalia activation scripts: plugin state management, location patching, model-usage setup.

let
  plugins = import ./_plugins.nix;
in
{
  lib,
  pkgs,
  ...
}:
{
  home.activation = {
    backupNoctaliaPluginSettings = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
      PLUGIN_STATE_DIR="$HOME/.local/state/noctalia/plugin-settings"
      mkdir -p "$PLUGIN_STATE_DIR"

      for PLUGIN_ID in ${lib.concatStringsSep " " plugins.needsBackup}; do
        PLUGIN_DIR="$HOME/.config/noctalia/plugins/$PLUGIN_ID"
        SETTINGS_PATH="$PLUGIN_DIR/settings.json"
        if [ -f "$SETTINGS_PATH" ]; then
          cp "$SETTINGS_PATH" "$PLUGIN_STATE_DIR/$PLUGIN_ID.json"
        fi
      done

      for PLUGIN_ID in ${lib.concatStringsSep " " plugins.needsMaterialization}; do
        PLUGIN_DIR="$HOME/.config/noctalia/plugins/$PLUGIN_ID"
        if [ -e "$PLUGIN_DIR" ] && [ ! -L "$PLUGIN_DIR" ]; then
          chmod -R u+w "$PLUGIN_DIR" 2>/dev/null || true
          rm -rf "$PLUGIN_DIR"
        fi
        if [ -e "$PLUGIN_DIR.backup" ] && [ ! -L "$PLUGIN_DIR.backup" ]; then
          chmod -R u+w "$PLUGIN_DIR.backup" 2>/dev/null || true
          rm -rf "$PLUGIN_DIR.backup"
        fi
      done
    '';

    materializeNoctaliaPlugins = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      PLUGIN_STATE_DIR="$HOME/.local/state/noctalia/plugin-settings"

      for PLUGIN_ID in ${lib.concatStringsSep " " plugins.needsMaterialization}; do
        PLUGIN_DIR="$HOME/.config/noctalia/plugins/$PLUGIN_ID"

        if [ ! -e "$PLUGIN_DIR" ]; then
          continue
        fi

        TMPDIR=$(mktemp -d)
        cp -aL "$PLUGIN_DIR/." "$TMPDIR/"
        rm -rf "$PLUGIN_DIR"
        mkdir -p "$PLUGIN_DIR"
        cp -a "$TMPDIR/." "$PLUGIN_DIR/"
        chmod -R u+w "$PLUGIN_DIR"
        chmod -R u+w "$TMPDIR"
        rm -rf "$TMPDIR"

        if [ -f "$PLUGIN_STATE_DIR/$PLUGIN_ID.json" ]; then
          cp "$PLUGIN_STATE_DIR/$PLUGIN_ID.json" "$PLUGIN_DIR/settings.json"
        fi
      done
    '';

    patchNoctaliaLocation = lib.hm.dag.entryAfter [ "materializeNoctaliaPlugins" ] ''
            SETTINGS_FILE="$HOME/.config/noctalia/settings.json"
            LOCATION_SECRET="/run/secrets/noctalia_location"
            MAWAQIT_SETTINGS="$HOME/.config/noctalia/plugins/mawaqit/settings.json"
            MODEL_USAGE_SETTINGS="$HOME/.config/noctalia/plugins/model-usage/settings.json"

            if [ -e "$SETTINGS_FILE" ]; then
              if [ -f "$LOCATION_SECRET" ]; then
                LOCATION=$(cat "$LOCATION_SECRET")
                CITY=$(printf '%s' "$LOCATION" | sed -E 's/^[[:space:]]*([^,]+).*$/\1/' | sed -E 's/[[:space:]]+$//')
                COUNTRY=$(printf '%s' "$LOCATION" | sed -nE 's/^[^,]+,[[:space:]]*(.+)$/\1/p' | sed -E 's/[[:space:]]+$//')
              else
                LOCATION=""
                CITY=""
                COUNTRY=""
              fi

              TMPFILE=$(mktemp)
              ${pkgs.jq}/bin/jq \
                --arg loc "$LOCATION" \
                '
                  .location.name = $loc
                ' \
                "$SETTINGS_FILE" > "$TMPFILE"

              # Replace the Nix store symlink with a mutable real file, or refresh an existing patched file.
              rm -f "$SETTINGS_FILE"
              mv "$TMPFILE" "$SETTINGS_FILE"

              if [ "$CITY" != "" ] && [ "$COUNTRY" != "" ]; then
                mkdir -p "$(dirname "$MAWAQIT_SETTINGS")"
                if [ -f "$MAWAQIT_SETTINGS" ]; then
                  TMPFILE=$(mktemp)
                  ${pkgs.jq}/bin/jq --arg city "$CITY" --arg country "$COUNTRY" '
                    .city = $city
                    | .country = $country
                  ' "$MAWAQIT_SETTINGS" > "$TMPFILE"
                  mv "$TMPFILE" "$MAWAQIT_SETTINGS"
                else
                  printf '{\n  "city": "%s",\n  "country": "%s"\n}\n' "$CITY" "$COUNTRY" > "$MAWAQIT_SETTINGS"
                fi
              fi

              mkdir -p "$(dirname "$MODEL_USAGE_SETTINGS")"
              if [ -f "$MODEL_USAGE_SETTINGS" ]; then
                TMPFILE=$(mktemp)
                ${pkgs.jq}/bin/jq '
                  (.providers //= {})
                  | (.providers.codex //= {})
                  | (.providers.zai //= {})
                  | (.providers.codex.enabled //= true)
                  | (.providers.zai.enabled //= true)
                ' "$MODEL_USAGE_SETTINGS" > "$TMPFILE"
                mv "$TMPFILE" "$MODEL_USAGE_SETTINGS"
              else
                cat > "$MODEL_USAGE_SETTINGS" <<'EOF'
      {
        "providers": {
          "codex": {
            "enabled": true
          },
          "zai": {
            "enabled": true
          }
        }
      }
      EOF
              fi
            fi
    '';
  };
}
