# MIME type associations for default applications.

{
  lib,
  constants,
  ...
}:

let
  inherit (lib) listToAttrs flatten mapAttrsToList;
  inherit (lib.attrsets) nameValuePair;
  defaultApps = {
    browser = [ "brave-browser.desktop" ];
    text = [ "org.gnome.TextEditor.desktop" ]; # Plain text editor
    image = [ "imv.desktop" ]; # Image viewer
    audio = [ "io.bassi.Amberol.desktop" ]; # Audio player (GNOME Amberol)
    video = [ "io.github.celluloid_player.Celluloid.desktop" ]; # Video player (GTK Celluloid)
    directory = [ "nautilus.desktop" ]; # File manager
    office = [ "libreoffice.desktop" ]; # Office suite
    pdf = [ "zathura.desktop" ]; # PDF viewer
    terminal = [ "${constants.terminalAppId}.desktop" ]; # Terminal emulator
    archive = [ "org.gnome.Nautilus.desktop" ]; # Nautilus handles archives via file-roller
  };

  # MIME type mappings - maps file categories to specific MIME types
  mimeMap = {
    # Plain text files
    text = [ "text/plain" ];

    # Image formats
    image = [
      "image/bmp" # Windows Bitmap
      "image/gif" # GIF images
      "image/jpeg" # JPEG images
      "image/jpg" # JPG images
      "image/png" # PNG images
      "image/svg+xml" # SVG vector graphics
      "image/tiff" # TIFF images
      "image/vnd.microsoft.icon" # Windows icons
      "image/webp" # WebP images
    ];

    # Audio formats
    audio = [
      "audio/aac" # AAC audio
      "audio/mpeg" # MP3 audio
      "audio/ogg" # OGG audio
      "audio/opus" # Opus audio
      "audio/wav" # WAV audio
      "audio/webm" # WebM audio
      "audio/x-matroska" # Matroska audio
    ];

    # Video formats
    video = [
      "video/mp2t" # MPEG-2 transport stream
      "video/mp4" # MP4 video
      "video/mpeg" # MPEG video
      "video/ogg" # OGG video
      "video/webm" # WebM video
      "video/x-flv" # Flash video
      "video/x-matroska" # Matroska video
      "video/x-msvideo" # AVI video
    ];

    # Directories
    directory = [ "inode/directory" ];

    # Web and URL schemes
    browser = [
      "text/html" # HTML files
      "x-scheme-handler/about" # about: URLs
      "x-scheme-handler/http" # HTTP URLs
      "x-scheme-handler/https" # HTTPS URLs
      "x-scheme-handler/unknown" # Unknown schemes
    ];

    # Office document formats
    office = [
      "application/vnd.oasis.opendocument.text" # ODT files
      "application/vnd.oasis.opendocument.spreadsheet" # ODS files
      "application/vnd.oasis.opendocument.presentation" # ODP files
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" # DOCX files
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" # XLSX files
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" # PPTX files
      "application/msword" # DOC files
      "application/vnd.ms-excel" # XLS files
      "application/vnd.ms-powerpoint" # PPT files
      "application/rtf" # RTF files
    ];

    # Document formats
    pdf = [ "application/pdf" ]; # PDF documents

    # Archive formats
    archive = [
      "application/zip" # ZIP archives
      "application/x-rar" # RAR archives
      "application/x-7z-compressed" # 7Z archives
      "application/x-tar" # TAR archives
      "application/x-compressed-tar" # tar.gz archives
      "application/x-bzip2-compressed-tar" # tar.bz2 archives
      "application/x-xz-compressed-tar" # tar.xz archives
      "application/gzip" # gzip files
    ];
  };

  associations = listToAttrs (
    flatten (mapAttrsToList (key: map (type: nameValuePair type defaultApps."${key}")) mimeMap)
  );
in
{
  xdg = {
    configFile."mimeapps.list".force = true;

    mimeApps = {
      enable = true;
      associations.added = associations;
      defaultApplications = associations;
    };
  };
}
