# Library list for nix-ld dynamic linker.
# Required by precompiled/non-Nix binaries (AppImages, game launchers, dev tools).
# Add missing libraries here — programs.nix-ld.libraries consumes this list directly.

{ pkgs }:

with pkgs;
[
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
]
