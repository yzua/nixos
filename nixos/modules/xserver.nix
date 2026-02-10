# X server for XWayland compatibility on Niri (Wayland).
_:

{
  services.xserver = {
    enable = true;
    # Keyboard layout configured in i18n.nix
  };
}
