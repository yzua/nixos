# Brave browser with declarative extensions.
{ ... }:
{
  imports = [
    ./extensions.nix # Declarative extension install list
  ];

  programs.brave = {
    enable = true;
  };
}
