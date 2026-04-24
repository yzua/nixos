# CUPS printing services with privacy hardening.

{
  config,
  constants,
  lib,
  pkgsStable,
  ...
}:

{
  options.mySystem.printing = {
    enable = lib.mkEnableOption "CUPS printing services with network printer discovery";
  };

  config = lib.mkIf config.mySystem.printing.enable {
    services.printing = {
      enable = true;
      drivers = [ pkgsStable.foo2zjs ]; # Driver for HP LaserJet P1102
      listenAddresses = [ "${constants.localhost}:${toString constants.ports.cups}" ]; # Restrict to localhost for security
      allowFrom = [ "localhost" ]; # Only allow local connections
      # PRIVACY: Disable job history and metadata retention
      extraConf = ''
        Browsing Off
        BrowseLocalProtocols none
        MaxJobs 10
        PreserveJobHistory No
        PreserveJobFiles No
      '';
    };
  };
}
