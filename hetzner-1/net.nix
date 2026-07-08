{ config, ... }:
{
  systemd.network = {
    enable = true;
    networks."10-eth" = {
      matchConfig.Name = "eth0";
      dns = config.custom.nameservers-hetzner;
      address = [
        "${config.custom.server."hetzner-1".public-ip-v4}/32"
        "${config.custom.server."hetzner-1".public-ip-v6}/64"
      ];
      routes = [
        {
          Gateway = "172.31.1.1";
          GatewayOnLink = true;
        }
        {
          Gateway = "fe80::1";
          GatewayOnLink = true;
        }
      ];
      linkConfig.RequiredForOnline = "yes";
    };
    links."10-eth" = {
      matchConfig.PermanentMACAddress = "92:00:07:6f:a1:f0";
      linkConfig.Name = "eth0";
    };
  };
}
