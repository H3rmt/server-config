{ config, ... }:
{
  systemd.network = {
    enable = true;
    networks."10-eth" = {
      matchConfig.Name = "eth0";
      dns = config.custom.nameservers;
      address = [
        "${config.custom.server."ovh-1".public-ip-v4}/32"
        "${config.custom.server."ovh-1".public-ip-v6}/128"
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

    networks."30-wg" = {
      matchConfig.Name = "wg0";
      address = [
        "${config.custom.server."ovh-1".private-ip}/24"
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
        RouteTable = "main";
      };
      wireguardPeers = [
        {
          PublicKey = "${config.custom.server."home-2".wireguard-public-key}";
          AllowedIPs = "${config.custom.server."home-2".private-ip}/32";
        }
        {
          PublicKey = "${config.custom.server."hetzner-1".wireguard-public-key}";
          AllowedIPs = "${config.custom.server."hetzner-1".private-ip}/32";
        }
        # { # Private access
        #   PublicKey = "laMDZ656KTbbj7edhy/EixACvUne8AvHXbzOdNym+Vk=";
        #   AllowedIPs = "10.0.0.201/32";
        # }
      ];
    };
  };
}
