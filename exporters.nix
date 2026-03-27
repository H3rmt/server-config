{ lib, config, ... }:
let
  host = config.networking.hostName;
  server = config.custom.server.${host};
  monitoringInterface = "wg0";
  hasWireGuard = server.wireguard-public-key != "";
in
{
  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = server.private-ip;
    openFirewall = false;
  };

  services.prometheus.exporters.wireguard = lib.mkIf hasWireGuard {
    enable = true;
    listenAddress = server.private-ip;
    openFirewall = false;
    interfaces = [ monitoringInterface ];
    latestHandshakeDelay = true;
    withRemoteIp = true;
  };
}
