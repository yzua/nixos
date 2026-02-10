# WakaTime plugin for Neovim code time tracking.

{
  pkgs,
  ...
}:

{
  programs.neovim = {
    plugins = [
      {
        plugin = pkgs.vimPlugins.vim-wakatime;
        config = ''
          " Point CLI to Nix-managed wakatime-cli
          let g:wakatime_CLIPath = "${pkgs.wakatime-cli}/bin/wakatime-cli"
        '';
      }
    ];
  };

  home.packages = [ pkgs.wakatime-cli ];
}
