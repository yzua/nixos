# Swaylock screen locker (fallback — Noctalia lock screen is primary).
# Colors handled by Stylix (base16 → swaylock color mapping).

{
  programs.swaylock = {
    enable = true;

    settings = {
      # Font
      font = "JetBrains Mono";
      font-size = 24;

      # Indicator
      indicator-idle-visible = false;
      indicator-radius = 100;
      indicator-thickness = 7;

      # Behavior
      show-failed-attempts = true;
      ignore-empty-password = true;

    };
  };
}
