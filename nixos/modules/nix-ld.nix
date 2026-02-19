# Nix-ld dynamic linker for running non-Nix binaries.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.mySystem.nixLd = {
    enable = lib.mkEnableOption "nix-ld dynamic linker for running non-Nix binaries";
  };

  config = lib.mkIf config.mySystem.nixLd.enable {
    programs.nix-ld = {
      enable = true;

      libraries = with pkgs; [
        # Core
        stdenv.cc.cc
        libgcc
        glibc
        glib
        zlib
        bzip2
        xz
        openssl
        cups

        # X11 and graphics
        libxcb
        libx11
        libxext
        libxi
        libxrender
        libxft
        libxcursor
        libxrandr
        libxinerama
        libxcomposite
        libxdamage
        libxfixes
        libxscrnsaver
        libxtst
        libxkbfile
        libxshmfence
        libGL

        # GTK/rendering stack (Chrome/Chromium)
        atk
        at-spi2-atk
        cairo
        gdk-pixbuf
        gtk3
        pango
        alsa-lib
        libdrm
        libxkbcommon
        mesa
        libgbm

        # System
        dbus
        systemd
        fontconfig
        freetype
        expat

        # Development
        libffi
        ncurses
        readline
        curl
        libxml2
        nss
        nspr

        # Media and formats
        sqlite
        icu
        libpng
        libjpeg
        libwebp
        libtiff
        librsvg
        harfbuzz
        graphite2
        pcre
        gmp
        libtasn1
        libunistring
        libidn2
        libpsl
        libssh2
        nghttp2
        libbsd
        libcap
        libseccomp
        libapparmor

        # Video/audio codecs
        ffmpegthumbnailer
        ffmpeg-full
        libva
        libvdpau
        intel-media-driver
      ];
    };
  };
}
