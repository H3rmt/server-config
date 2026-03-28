{ config, ... }:
{
  systemd.network = {
    enable = true;
    networks."10-eth" = {
      matchConfig.Name = "eth0";
      dns = config.custom.nameservers-hetzner;
      address = [
        "${config.custom.server."hetzner-1".public-ip-v4}/32"
        "${config.custom.server."hetzner-1".public-ip-v6}/128"
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

    networks."30-wg" = {
      matchConfig.Name = "wg0";
      address = [
        "${config.custom.server."hetzner-1".private-ip}/24"
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
        ListenPort = 51820;
      };
      wireguardPeers = [
        {
          PublicKey = "${config.custom.server."home-1".wireguard-public-key}";
          AllowedIPs = "${config.custom.server."home-1".private-ip}/32";
        }
        {
          PublicKey = "${config.custom.server."ovh-1".wireguard-public-key}";
          AllowedIPs = "10.0.0.0/24";
          Endpoint = "${config.custom.server."ovh-1".public-ip-v4}:51820";
          PersistentKeepalive = 30;
        }
      ];
    };
  };
}
