# Niri compositor modules aggregation.

{ inputs, ... }:

{
  imports = [
    inputs.niri.homeModules.config # Niri settings (programs.niri.settings)
    inputs.niri.homeModules.stylix # Stylix integration for niri (border colors, cursor)
    ./main.nix # Main compositor settings (autostart, workspaces, environment)
    ./binds.nix # Keybindings and custom scripts
    ./idle.nix # Idle management (swayidle)
    ./lock.nix # Screen locker (swaylock fallback)
    ./input.nix # Input devices (keyboard, mouse, touchpad)
    ./layout.nix # Layout settings (columns, gaps, focus)
    ./rules.nix # Window rules (opacity, rounding, floating)
  ];
}
