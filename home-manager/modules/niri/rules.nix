# Niri window rules (floating, opacity, workspace assignments, positioning).
{ constants, ... }:
{
  programs.niri.settings.window-rules =
    let
      r = 0.0; # Square corners
    in
    [
      {
        geometry-corner-radius = {
          top-left = r;
          top-right = r;
          bottom-left = r;
          bottom-right = r;
        };
        clip-to-geometry = true;
      }

      {
        matches = [ { app-id = "^io\\.github\\.celluloid_player\\.Celluloid$"; } ];
        open-floating = true;
      }
      {
        matches = [ { app-id = "^io\\.bassi\\.Amberol$"; } ];
        open-floating = true;
      }
      {
        matches = [ { app-id = "^imv$"; } ];
        open-floating = true;
      }
      {
        matches = [ { app-id = "^showmethekey-gtk$"; } ];
        open-floating = true;
      }

      {
        matches = [
          {
            app-id = "^org\\.telegram\\.desktop$";
            title = "^Media viewer$";
          }
        ];
        open-floating = true;
      }

      {
        matches = [ { app-id = "^org\\.gnome\\.NautilusPreviewer$"; } ];
        open-floating = true;
      }
      {
        matches = [ { app-id = "^(pwvucontrol|nm-connection-editor|blueman-manager)$"; } ];
        open-floating = true;
      }
      {
        matches = [
          { app-id = "^org\\.gnome\\.Calculator$"; }
          { app-id = "^qalculate-gtk$"; }
        ];
        open-floating = true;
      }

      {
        matches = [ { app-id = "^org\\.keepassxc\\.KeePassXC$"; } ];
        open-on-workspace = "󰦝 vpn";
        open-floating = true;
      }
      {
        matches = [
          { app-id = "^xdg-desktop-portal-gtk$"; }
          { app-id = "^xdg-desktop-portal-gnome$"; }
        ];
        open-floating = true;
      }

      {
        matches = [ { title = "^Picture-in-Picture$"; } ];
        open-floating = true;
      }
      {
        matches = [ { app-id = "^scratchpad$"; } ];
        open-floating = true;
      }
      {
        matches = [ { app-id = "^(${constants.terminalAppId}|kitty|foot)$"; } ];
        opacity = 0.92;
      }
      {
        matches = [ { app-id = "^(librewolf|librewolf-main|librewolf-i2pd)$"; } ];
      }

      {
        matches = [ { app-id = "^1password$"; } ];
        block-out-from = "screen-capture";
      }

      {
        matches = [ { app-id = "^xwaylandvideobridge$"; } ];
        opacity = 0.0;
        block-out-from = "screen-capture";
      }

      {
        matches = [ { is-floating = true; } ];
        shadow.enable = true;
      }
      {
        matches = [ { is-active = false; } ];
        opacity = 0.95;
      }
      {
        matches = [ { title = "^Picture-in-Picture$"; } ];
        default-floating-position = {
          x = 32;
          y = 32;
          relative-to = "bottom-right";
        };
        default-column-width.fixed = 480;
        default-window-height.fixed = 270;
      }

      {
        matches = [ { app-id = "^scratchpad$"; } ];
        default-floating-position = {
          x = 0;
          y = 0;
          relative-to = "top";
        };
        default-column-width = {
          proportion = 0.6;
        };
        default-window-height = {
          proportion = 0.4;
        };
      }

      {
        matches = [
          {
            app-id = "^(brave|brave-browser|firefox|chromium|librewolf|librewolf-main|librewolf-personal|librewolf-work|librewolf-banking|librewolf-shopping|librewolf-illegal|librewolf-i2pd)";
          }
        ];
        scroll-factor = 0.75;
      }

      # Workspace assignments
      {
        matches = [
          {
            app-id = "^(librewolf|librewolf-main|librewolf-personal|librewolf-work|librewolf-banking|librewolf-shopping|librewolf-illegal)$";
          }
        ];
        open-on-workspace = "󰖟 browser";
        default-column-width.proportion = 1.0;
      }
      {
        matches = [ { app-id = "^librewolf-i2pd$"; } ];
        open-on-workspace = "󰦝 vpn";
        default-column-width.proportion = 1.0;
      }

      {
        matches = [ { app-id = "^(brave|brave-browser)$"; } ];
        open-on-workspace = "󰖟 browser";
        default-column-width.proportion = 1.0;
      }

      {
        matches = [ { app-id = "^(${constants.editorAppId})$"; } ];
        open-on-workspace = "󰨞 editor";
      }

      {
        matches = [ { app-id = "^(${constants.terminalAppId})$"; } ];
        excludes = [ { app-id = "^scratchpad$"; } ];
        open-on-workspace = "󰨞 editor";
      }

      {
        matches = [ { app-id = "^vesktop$"; } ];
        open-on-workspace = "󰍡 social";
      }

      {
        matches = [ { app-id = "^org\\.telegram\\.desktop$"; } ];
        excludes = [
          {
            app-id = "^org\\.telegram\\.desktop$";
            title = "^Media viewer$";
          }
        ];
        open-on-workspace = "󰍡 social";
      }

      {
        matches = [ { app-id = "^FreeTube$"; } ];
        open-on-workspace = "󰎆 media";
      }

      {
        matches = [ { app-id = "^muffon$"; } ];
        open-on-workspace = "󰎆 media";
      }

      {
        matches = [ { app-id = "^nuclear$"; } ];
        open-on-workspace = "󰎆 media";
      }

      {
        matches = [ { app-id = "^Mullvad VPN$"; } ];
        open-on-workspace = "󰦝 vpn";
        open-floating = true;
      }
    ];
}
