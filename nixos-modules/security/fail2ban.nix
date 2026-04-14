# Fail2ban intrusion prevention and audit analysis tools.

{
  pkgsStable,
  config,
  lib,
  ...
}:

{
  options.mySystem.fail2ban = {
    enable = lib.mkEnableOption "fail2ban intrusion prevention";
  };

  config = lib.mkIf config.mySystem.fail2ban.enable {
    environment.systemPackages = [ pkgsStable.audit ];

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
  };
}
