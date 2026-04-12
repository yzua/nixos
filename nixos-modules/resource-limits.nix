# System-level resource limits: systemd timeouts, PAM session limits.

{
  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "30s";
    # Avoid greetd/user@ login loops when user manager startup is heavy on cold boot.
    DefaultTimeoutStartSec = "180s";
    DefaultDeviceTimeoutSec = "30s";
    DefaultLimitNOFILE = 200000;
    DefaultLimitNPROC = 65536;
    # Disable hardware watchdog arming on reboot/shutdown to prevent
    # "watchdog0: watchdog did not stop!" and unnecessary 10-minute fallback timer.
    RuntimeWatchdogSec = "0";
    RebootWatchdogSec = "0";
    KExecWatchdogSec = "0";
  };

  # Keep user-session app scopes from delaying reboot for the default 90s.
  systemd.user.extraConfig = ''
    DefaultTimeoutStopSec=30s
  '';

  # PAM session limits (consolidated — includes core dump disable from security/hardening.nix)
  security.pam.loginLimits = [
    {
      domain = "*";
      type = "hard";
      item = "core";
      value = "0"; # Disable core dumps (security hardening)
    }
    {
      domain = "*";
      type = "-";
      item = "nofile";
      value = 200000;
    }
    {
      domain = "*";
      type = "-";
      item = "nproc";
      value = 65536;
    }
    {
      domain = "*";
      type = "-";
      item = "stack";
      value = "65536"; # 64 MB
    }
  ];
}
