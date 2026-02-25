# Z-shell (Oh My Zsh) configuration.

{ config, ... }:

{
  imports = [
    ./aliases.nix # Shell aliases
    ./config.nix # Zsh core options, history, Oh My Zsh, plugins, keymap
    ./local-vars.nix # Local variables (editor, pager, FZF, XDG tool caches)
    ./functions.nix # initContent functions (nix helpers, agent wrappers, utilities)
  ];

  # PATH extensions previously in initContent (go/bin, .deno/bin, etc. in language modules)
  home.sessionPath = [
    "${config.home.homeDirectory}/.cargo/bin"
    "${config.home.homeDirectory}/.config/composer/vendor/bin"
    "${config.home.homeDirectory}/.local/share/gem/ruby/3.1.0/bin"
    "${config.home.homeDirectory}/.local/share/uv/tools"
  ];

  # Docker build settings (in sessionVariables so systemd services/cron can use them too)
  home.sessionVariables = {
    DOCKER_BUILDKIT = "1";
    COMPOSE_DOCKER_CLI_BUILD = "1";
  };
}
