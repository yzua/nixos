# Environment variables and session settings.

{
  user,
  constants,
  ...
}:

let
  xdgBinHome = "$HOME/.local/bin";
  inherit (constants) terminal editor;
in
{
  environment.sessionVariables = {
    # Default terminal emulator for applications that need one
    TERMINAL = terminal;

    # Session class for systemd user services (e.g. localsearch indexer).
    # greetd/PAM doesn't set this, so systemd ConditionEnvironment checks fail.
    XDG_SESSION_CLASS = "user";

    # Default text editor for applications that need one
    EDITOR = editor;

    # Force GTK4 apps to use GL renderer instead of Vulkan.
    # Fixes black/broken windows with NVIDIA (VK_ERROR_OUT_OF_DATE_KHR).
    GSK_RENDERER = "gl";

    # XDG Base Directory specification for user binaries
    XDG_BIN_HOME = xdgBinHome;

    # XDG data directories - include Flatpak exports for app launchers
    # This ensures wofi and other launchers can find Flatpak applications
    XDG_DATA_DIRS = [
      "/var/lib/flatpak/exports/share"
      "/home/${user}/.local/share/flatpak/exports/share"
      "/run/current-system/sw/share"
    ];

    # System PATH with additional directories
    PATH = [ xdgBinHome ];
  };
}
