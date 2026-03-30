{ config, ... }:
{
  systemd.network = {
    enable = true;
    networks."10-eth" = {
      matchConfig.Name = "eth0";
      dns = config.custom.nameservers;
      address = [
        "192.168.187.12/32"
      ];
      routes = [
        {
          Gateway = "192.168.187.1";
          GatewayOnLink = true;
        }
      ];
      linkConfig.RequiredForOnline = "no";
    };
    links."10-eth" = {
      matchConfig.PermanentMACAddress = "30:9c:23:ce:db:65";
      linkConfig.Name = "eth0";
    };

    networks."30-wg" = {
      matchConfig.Name = "wg0";
      address = [
        "${config.custom.server."home-2".private-ip}/24"
      ];
      linkConfig.RequiredForOnline = "yes";
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
          PublicKey = "${config.custom.server."ovh-1".wireguard-public-key}";
          AllowedIPs = "${config.custom.server."ovh-1".private-ip}/32";
          Endpoint = "${config.custom.server."ovh-1".public-ip-v4}:51820";
          PersistentKeepalive = 30;
        }
        {
          PublicKey = "${config.custom.server."hetzner-1".wireguard-public-key}";
          AllowedIPs = "${config.custom.server."hetzner-1".private-ip}/32";
          Endpoint = "${config.custom.server."hetzner-1".public-ip-v4}:51820";
          PersistentKeepalive = 30;
        }
      ];
    };
  };
}
