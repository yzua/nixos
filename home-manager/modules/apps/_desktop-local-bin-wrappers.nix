# Local-bin wrapper scripts wired from scripts/apps (templated where needed).

{ pkgs, user }:

let
  renderScript =
    scriptPath: replacements:
    builtins.replaceStrings (map (entry: entry.from) replacements) (map (
      entry: entry.to
    ) replacements) (builtins.readFile scriptPath);
in
{
  ".local/bin/element-desktop-keyring" = {
    executable = true;
    text = renderScript ../../../scripts/apps/element-desktop-keyring.sh [
      {
        from = "__ELEMENT_DESKTOP_BIN__";
        to = "${pkgs.element-desktop}/bin/element-desktop";
      }
    ];
  };

  ".local/bin/browser-select" = {
    executable = true;
    text = builtins.readFile ../../../scripts/apps/browser-select.sh;
  };

  ".local/bin/youtube-mpv" = {
    executable = true;
    text = renderScript ../../../scripts/apps/youtube-mpv.sh [
      {
        from = "__NOTIFY_SEND_BIN__";
        to = "${pkgs.libnotify}/bin/notify-send";
      }
    ];
  };

  ".local/bin/xdg-open" = {
    executable = true;
    text = renderScript ../../../scripts/apps/xdg-open-wrapper.sh [
      {
        from = "__USER__";
        to = user;
      }
    ];
  };
}
