# Modern dbus-broker (faster and more secure than daemon) + journald hardening.

_:

{
  services.dbus.implementation = "broker";

  # === journald Hardening ===
  # Rate-limit journal to prevent log flooding attacks, cap storage,
  # and disable forwarding to prevent log exfiltration.
  # Loki/Alloy retains 30 days, so keep journal lean.
  services.journald = {
    extraConfig = ''
      # Rate limit: max 200 messages per 30s window per service
      RateLimitIntervalSec=30s
      RateLimitBurst=200
      # Cap journal storage to 500MB
      SystemMaxUse=500M
      SystemMaxFileSize=50M
      SystemKeepFree=1G
      MaxRetentionSec=7day
      # Don't forward logs to other services (prevents exfiltration)
      ForwardToSyslog=no
      ForwardToWall=no
      # Compress old journal entries
      Compress=yes
      # Split journals per-user for isolation
      SplitMode=uid
    '';
  };
}
