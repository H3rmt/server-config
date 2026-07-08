{ config, ... }:
{
  systemd.network = {
    enable = true;
    networks."10-eth" = {
      matchConfig.Name = "eth0";
      dns = config.custom.nameservers;
      address = [
        "${config.custom.server."ovh-1".public-ip-v4}/32"
        "${config.custom.server."ovh-1".public-ip-v6}/64"
      ];
      routes = [
        {
          Gateway = "37.187.250.254";
          GatewayOnLink = true;
        }
        {
          Gateway = "2001:41d0:000c:02ff:00ff:00ff:00ff:00ff";
          GatewayOnLink = true;
        }
      ];
      linkConfig.RequiredForOnline = "yes";
    };
    links."10-eth" = {
      matchConfig.PermanentMACAddress = "0c:c4:7a:6b:0d:98";
      linkConfig.Name = "eth0";
    };
  };
}
