# Noctalia Shell desktop environment.

{
  inputs,
  pkgs,
  constants,
  ...
}:

let
  colorschemeJson = import ./_colorscheme.nix { inherit constants; };

  pluginUrl = "https://github.com/noctalia-dev/noctalia-plugins";
  patchedNoctaliaPackage =
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
      (old: {
        postInstall = (old.postInstall or "") + ''
          substituteInPlace $out/share/noctalia-shell/Modules/Bar/Widgets/Workspace.qml \
            --replace-fail \
              'return ThemeIcons.iconForAppId(modelData.appId?.toLowerCase());' \
              'return ThemeIcons.iconForAppId(modelData?.appId?.toLowerCase());'
        '';
      });

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
  programs.noctalia-shell.package = patchedNoctaliaPackage;

  # Allow the activation script to overwrite the mutable settings.json
  # (patched at activation time by the sops location injector)
  xdg.configFile."noctalia/settings.json".force = true;

  home.file = {
    ".config/noctalia/colorschemes/GruvboxAlt/GruvboxAlt.json".text = colorschemeJson;
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
