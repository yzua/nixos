# Bat (cat clone) configuration.

{ constants, ... }:

{
  programs.bat = {
    enable = true;
    config = {
      theme = constants.themeNames.bat;
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
