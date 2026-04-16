# System-level resource limits: systemd timeouts, PAM session limits.

let
  # Shared between systemd Manager defaults and PAM login limits.
  maxOpenFiles = 200000;
  maxProcesses = 65536;
in
{
  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "30s";
    # Avoid greetd/user@ login loops when user manager startup is heavy on cold boot.
    DefaultTimeoutStartSec = "180s";
    DefaultDeviceTimeoutSec = "30s";
    DefaultLimitNOFILE = maxOpenFiles;
    DefaultLimitNPROC = maxProcesses;
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

  # PAM session limits. Core dump limit (hard core=0) complements kernel.core_pattern
  # and systemd.coredump.disable in security/hardening.nix (defense-in-depth).
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
      value = maxOpenFiles;
    }
    {
      domain = "*";
      type = "-";
      item = "nproc";
      value = maxProcesses;
    }
    {
      domain = "*";
      type = "-";
      item = "stack";
      value = "65536"; # 64 MB
    }
  ];
}
