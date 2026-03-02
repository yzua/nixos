# I2PD router service with optional firewall opening.
{
  config,
  lib,
  ...
}:

let
  cfg = config.mySystem.i2pd;
in
{
  options.mySystem.i2pd = {
    enable = lib.mkEnableOption "I2PD (I2P router) service";

    notransit = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = "Disable transit tunnel participation to reduce relay traffic.";
    };

    bandwidth = lib.mkOption {
      type = with lib.types; nullOr int;
      default = null;
      example = 128;
      description = "Router bandwidth cap in KB/s. Null keeps the upstream i2pd default.";
    };

    port = lib.mkOption {
      type = with lib.types; nullOr port;
      default = null;
      example = 12345;
      description = "Fixed external I2P transport port. Null lets i2pd choose automatically.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = "Open TCP/UDP firewall rules for the configured i2pd port.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.openFirewall || cfg.port != null;
        message = "mySystem.i2pd.openFirewall requires mySystem.i2pd.port to be set to a fixed value.";
      }
    ];

    services.i2pd = {
      enable = true;
      logLevel = lib.mkDefault "error";
      inherit (cfg) notransit bandwidth port;

      proto = {
        http.enable = lib.mkDefault true;
        httpProxy.enable = lib.mkDefault true;
        socksProxy.enable = lib.mkDefault true;
      };
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
      allowedUDPPorts = [ cfg.port ];
    };
  };
}
