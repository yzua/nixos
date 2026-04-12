# Noctalia Shell desktop environment.

{
  inputs,
  ...
}:

let
  pluginUrl = "https://github.com/noctalia-dev/noctalia-plugins";

  pluginsJson = builtins.toJSON {
    version = 2;
    sources = [
      {
        enabled = true;
        name = "Noctalia Plugins";
        url = pluginUrl;
      }
    ];
    states = builtins.listToAttrs (
      map
        (name: {
          inherit name;
          value = {
            enabled = true;
            sourceUrl = pluginUrl;
          };
        })
        [
          "model-usage"
          "keybind-cheatsheet"
          "mawaqit"
          "music-search"
          "browser-launcher"
        ]
    );
  };
in
{
  imports = [
    inputs.noctalia.homeModules.default
    (import ./bar.nix { })
    ./settings.nix
    ./activation.nix
  ];

  # Required for system tray icons (SNI protocol).
  services.status-notifier-watcher.enable = true;

  programs.noctalia-shell.enable = true;

  # Allow the activation script to overwrite the mutable settings.json
  # (patched at activation time by the sops location injector)
  xdg.configFile."noctalia/settings.json".force = true;

  home.file = {
    ".config/noctalia/colorschemes/GruvboxAlt/GruvboxAlt.json".source = ./colorschemes/GruvboxAlt.json;
    ".config/noctalia/plugins/model-usage" = {
      source = ./plugins/model-usage;
      force = true;
    };
    ".config/noctalia/plugins/keybind-cheatsheet" = {
      source = ./plugins/keybind-cheatsheet;
      force = true;
    };
    ".config/noctalia/plugins/mawaqit" = {
      source = ./plugins/mawaqit;
      force = true;
    };
    ".config/noctalia/plugins/music-search" = {
      source = ./plugins/music-search;
      force = true;
    };
    ".config/noctalia/plugins/browser-launcher" = {
      source = ./plugins/browser-launcher;
      force = true;
    };
    ".config/noctalia/plugins.json".text = pluginsJson;
  };
}
