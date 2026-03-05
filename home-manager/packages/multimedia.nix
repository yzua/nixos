# Multimedia packages for media playback and processing.
{
  pkgs,
  pkgsStable,
  ...
}:

{
  home.packages =
    (with pkgsStable; [
      amberol # GNOME audio player
      ffmpeg # Multimedia processing toolkit
      mediainfo # Media file analyzer
    ])
    ++ (with pkgs; [
      freetube # YouTube client (firejail-wrapped)
      muffon # Desktop music streaming and discovery client
      nuclear # Privacy-focused music player and discovery
    ]);
}
