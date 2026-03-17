{ config, ... }:
{
  systemd.network = {
    enable = true;
    networks."10-eth" = {
      matchConfig.Name = "eth0";
      dns = config.custom.nameservers;
      address = [
        "192.168.187.10/32"
      ];
      routes = [
        {
          Gateway = "192.168.187.1";
          GatewayOnLink = true;
        }
      ];
      linkConfig.RequiredForOnline = "yes";
    };
    links."10-eth" = {
      matchConfig.PermanentMACAddress = "00:19:99:9f:ee:92";
      linkConfig.Name = "eth0";
    };

    networks."30-wg" = {
      matchConfig.Name = "wg0";
      address = [
        "${config.server."home-1".private-ip}/24"
      ];
      linkConfig.RequiredForOnline = "no";
    };
    netdevs."30-wg" = {
      netdevConfig = {
        Name = "wg0";
        Kind = "wireguard";
      };
      wireguardConfig = {
        PrivateKeyFile = config.age.secrets.wireguard_private.path;
      };
      wireguardPeers = [
        {
          PublicKey = "${config.server."ovh-1".wireguard-public-key}";
          AllowedIPs = "10.0.0.0/24";
          Endpoint = "ovh-1.h3rmt.dev:51820";
          PersistentKeepalive = 30;
        }
      ];
    };
  };
}
