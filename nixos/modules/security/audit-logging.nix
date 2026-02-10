# Fail2ban intrusion prevention and audit analysis tools.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.mySystem.auditLogging = {
    enable = lib.mkEnableOption "Security event logging with fail2ban";
  };

  config = lib.mkIf config.mySystem.auditLogging.enable {
    services.fail2ban = {
      enable = true;
      maxretry = 5;
      bantime = "1h";
      bantime-increment = {
        enable = true;
        multipliers = "1 2 4 8 16 32 64";
        maxtime = "168h"; # 1 week
      };
    };

    environment.systemPackages = with pkgs; [
      audit # provides aureport, ausearch, auditctl, etc.
    ];
  };
}
