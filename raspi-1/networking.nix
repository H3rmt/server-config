{ lib, config, ... }: {
  systemd.network = {
    enable = true;
    networks."10-eth" = {
      matchConfig.Name = "eth0";
      # dns = config.nameservers;
      address = [
        "192.168.187.45/32"
      ];
      routes = [
        { Gateway = "192.168.187.1"; GatewayOnLink = true; }
      ];
      linkConfig.RequiredForOnline = "yes";
    };
    networks."30-wg" = {
      matchConfig.Name = "wg0";
      address = [
        "${config.server.raspi-1.private-ip}/24"
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
          PublicKey = "${config.server.main-2.public-key-wg}";
          AllowedIPs = "${config.server.main-2.private-ip}/32";
          Endpoint = "159.69.206.86:${toString config.ports.exposed.wireguard}";
          PersistentKeepalive = 25;
        }
        {
          PublicKey = "${config.server.main-1.public-key-wg}";
          AllowedIPs = "${config.server.main-1.private-ip}/32";
          Endpoint = "128.140.32.233:${toString config.ports.exposed.wireguard}";
          PersistentKeepalive = 25;
        }
      ];
    };

    links."10-eth" = {
      matchConfig.PermanentMACAddress = "b8:27:eb:ab:d4:6b";
      linkConfig.Name = "eth0";
    };
  };
}
