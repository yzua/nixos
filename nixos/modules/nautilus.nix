# Nautilus (GNOME Files) with extensions, thumbnails, and automounting.
{
  config,
  lib,
  pkgsStable,
  ...
}:

{
  options.mySystem.nautilus = {
    enable = lib.mkEnableOption "GNOME Files (Nautilus) with thumbnails and automounting";
  };

  config = lib.mkIf config.mySystem.nautilus.enable {
    # Nautilus 43+ natively supports "Open in Terminal" via X-Terminal* desktop
    # entry keys (Ghostty's .desktop already declares these). The separate
    # nautilus-open-any-terminal extension is no longer needed and causes duplicates.

    environment.systemPackages = with pkgsStable; [
      nautilus
      nautilus-python
      file-roller
      sushi # Quick Look-style file previewer

      # Thumbnail generation
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-bad
      poppler-utils
      ffmpegthumbnailer
      gnome-epub-thumbnailer
      webp-pixbuf-loader
      f3d # 3D model thumbnails (STL, OBJ, glTF)

      loupe # GNOME image viewer
    ];

    services = {
      gvfs = {
        enable = true;
        package = pkgsStable.gvfs;
      };
      tumbler.enable = true;
      udisks2.enable = true;
    };

    # Passwordless mounting for wheel group members
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if ((action.id == "org.freedesktop.udisks2.filesystem-mount-system" ||
             action.id == "org.freedesktop.udisks2.filesystem-mount") &&
            subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
    '';
  };
}
