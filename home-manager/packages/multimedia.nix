# Multimedia packages for media playback and processing.
{ pkgsStable, ... }:

{
  home.packages = with pkgsStable; [
    amberol # GNOME audio player
    ffmpeg # Multimedia processing toolkit
    mediainfo # Media file analyzer
  ];
}
