# Noctalia Shell desktop environment.

{
  config,
  inputs,
  pkgs,
  ...
}:

let
  apiQuotaScript = "bash ${../../../scripts/ai/api-quota}/api-quota.sh";
  apiQuotaPlugin = pkgs.runCommandLocal "noctalia-ai-quota-plugin" { } ''
    mkdir -p "$out"
    cp -r ${./plugins/ai-quota}/. "$out/"
    substituteInPlace \
      "$out/Main.qml" \
      "$out/BarWidget.qml" \
      "$out/QuotaPanel.qml" \
      "$out/Panel.qml" \
      --replace-fail "@API_QUOTA_SCRIPT@" "${apiQuotaScript}"
  '';
  pluginsJson = builtins.toJSON {
    version = 2;
    sources = [
      {
        enabled = true;
        name = "Noctalia Plugins";
        url = "https://github.com/noctalia-dev/noctalia-plugins";
      }
    ];
    states = {
      "ai-quota" = {
        enabled = true;
        sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
      };
    };
  };
in
{
  imports = [
    inputs.noctalia.homeModules.default
    (import ./bar.nix { })
    ./settings.nix
  ];

  # Required for system tray icons (SNI protocol).
  services.status-notifier-watcher.enable = true;

  programs.noctalia-shell.enable = true;

  home.file = {
    ".config/noctalia/plugins/ai-quota".source = apiQuotaPlugin;
    ".config/noctalia/plugins.json".text = pluginsJson;
  };
}
