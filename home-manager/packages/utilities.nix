# General utilities: archive tools, system management, and audio control.

{ pkgs, ... }:

{
  home.packages = with pkgs; [
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

    # Device management
    udisks
    udiskie

    # System tools
    desktop-file-utils
    file # MIME type detection (used by yazi file manager)
    libsecret
    lsof
  ];
}
