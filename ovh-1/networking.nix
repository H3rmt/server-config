{ lib, config, ... }: {
  systemd.network = {
    enable = true;
    networks."10-eth" = {
      matchConfig.Name = "eth0";
      dns = config.nameservers;
      address = [
        "${config.server."${config.hostnames.ovh-2}".public-ip}/32"
        "${config.server."${config.hostnames.ovh-2}".public-ip-v6}/128"
      ];
      routes = [
        { Gateway = "2001:41d0:000c:02ff:00ff:00ff:00ff:00ff"; GatewayOnLink = true; }
        { Gateway = "37.187.250.254"; GatewayOnLink = true; }
      ];
      linkConfig.RequiredForOnline = "yes";
    };
    networks."30-wg" = {
      matchConfig.Name = "wg0";
      address = [
        "${config.server."${config.hostnames.ovh-2}".private-ip}/24"
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
        ListenPort = config.ports.exposed.wireguard;
      };
      wireguardPeers = [
        {
          PublicKey = "${config.server."${config.hostnames.raspi-1}".wireguard-public-key }";
          AllowedIPs = "${config.server."${config.hostnames.raspi-1}".private-ip}/32";
        }
        {
          PublicKey = "${config.server."${config.hostnames.main-1}".wireguard-public-key }";
          AllowedIPs = "${config.server."${config.hostnames.main-1}".private-ip}/32";
          Endpoint = "${config.server."${config.hostnames.main-1}".public-ip}:${toString config.ports.exposed.wireguard}";
          PersistentKeepalive = 25;
        }
        {
          PublicKey = "${config.server."${config.hostnames.main-2}".wireguard-public-key }";
          AllowedIPs = "${config.server."${config.hostnames.main-2}".private-ip}/32";
          Endpoint = "${config.server."${config.hostnames.main-2}".public-ip}:${toString config.ports.exposed.wireguard}";
          PersistentKeepalive = 25;
        }
      ];
    };

    links."10-eth" = {
      matchConfig.PermanentMACAddress = "96:00:03:4d:13:4f";
      linkConfig.Name = "eth0";
    };
  };
}
