# User accounts, default shell, and group memberships.
{ pkgs, user, ... }:

{
  programs.zsh.enable = true;

  users = {
    defaultUserShell = pkgs.zsh;

    users.${user} = {
      isNormalUser = true;
      extraGroups = [
        "networkmanager"
        "wheel"
        "video"
        "input"
        "render"
        "audio"
        "i2c"
      ];
    };
  };
}
