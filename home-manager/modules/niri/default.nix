# Niri compositor modules aggregation.

{ inputs, ... }:

{
  imports = [
    inputs.niri.homeModules.config # Niri settings (programs.niri.settings)
    inputs.niri.homeModules.stylix # Stylix integration for niri (border colors, cursor)
    ./main.nix # Main compositor settings (layout, outputs, window rules, animations)
    ./binds.nix # Keybindings and custom scripts
    ./idle.nix # Idle management (swayidle)
    ./lock.nix # Screen locker (swaylock fallback)
  ];
}
