# General utilities: archive tools, system management, and audio control.
{ pkgsStable, ... }:

{
  home.packages = with pkgsStable; [
    # Application packaging
    appimage-run

    # Archive and compression
    bzip2
    gzip
    p7zip
    unrar
    unzip
    xz
    zip

    # Audio control (easyeffects managed by services.easyeffects)
    pwvucontrol

    # Development utilities
    tree
    xxd

    # Device management
    udisks
    udiskie

    # Media optimization
    jpegoptim
    optipng

    # System tools
    desktop-file-utils
    file # MIME type detection (used by yazi file manager)
    libsecret
    lsof

    # Terminal image display
    ueberzugpp
  ];
}
