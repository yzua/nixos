# Htop (interactive process viewer) configuration.

{
  programs.htop = {
    enable = true;

    settings = {
      tree_view = 1;
    };
  };
}
