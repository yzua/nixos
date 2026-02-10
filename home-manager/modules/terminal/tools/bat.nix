# Bat (cat clone) configuration.

{
  programs.bat = {
    enable = true;
    config = {
      theme = "gruvbox-dark";
      style = "numbers,changes,header";
      map-syntax = [
        "*.nix:Nix"
        "*.kdl:KDL"
        "justfile:Make"
        ".envrc:Bash"
      ];
    };
  };
}
