# Yggdrasil mesh network overlay for encrypted IPv6 routing.

{
  config,
  lib,
  user,
  ...
}:

{
  options.mySystem.yggdrasil = {
    enable = lib.mkEnableOption "Yggdrasil mesh networking";
  };

  config = lib.mkIf config.mySystem.yggdrasil.enable {
    # Yggdrasil uses IPv6 addressing internally, so kernel IPv6 must stay enabled.
    # This does not require native ISP IPv6 connectivity.
    networking.enableIPv6 = lib.mkForce true;

    services.yggdrasil = {
      enable = true;
      persistentKeys = true;

      settings = {
        Peers = [
          # Public seed peers (update occasionally if one goes offline).
          "tls://vpn.ltha.de:443?key=0000006149970f245e6cec43664bce203f2514b60a153e194f31e2b229a1339d"
          "tls://yggdrasil.neilalexander.dev:64648?key=ecbbcb3298e7d3b4196103333c3e839cfe47a6ca47602b94a6d596683f6bb358"
          "quic://ip4.fvm.mywire.org:443?key=000000000143db657d1d6f80b5066dd109a4cb31f7dc6cb5d56050fffb014217"
          "tls://ygg.jjolly.dev:3443"
        ];

        # Do not accept inbound peer sessions by default.
        Listen = [ ];
      };
    };

    # Allow the primary user to query the local admin socket with yggdrasilctl.
    users.users.${user}.extraGroups = [ "yggdrasil" ];
  };
}
