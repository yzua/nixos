# Noctalia Shell desktop environment.

{
  inputs,
  pkgs,
  constants,
  ...
}:

let
  colorschemeJson = import ./_colorscheme.nix { inherit constants; };
  plugins = import ./_plugins.nix;

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
      map (name: {
        inherit name;
        value = {
          enabled = true;
          sourceUrl = pluginUrl;
        };
      }) plugins.all
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
  }
  // builtins.listToAttrs (
    map (name: {
      name = ".config/noctalia/plugins/${name}";
      value = {
        source = ./plugins/${name};
        force = true;
      };
    }) plugins.all
  )
  // {
    ".config/noctalia/plugins.json".text = pluginsJson;
  };
}
