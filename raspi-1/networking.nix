{ lib, config, ... }: {
  systemd.network = {
    enable = true;
    networks."10-eth" = {
      matchConfig.Name = "eth0";
      dns = config.nameservers;
      address = [
        "192.168.187.45/32"
      ];
      routes = [
        { Gateway = "192.168.187.1"; }
        { Destination = "10.0.69.0/24"; Gateway = "192.168.187.1"; }
      ];
      linkConfig.RequiredForOnline = "yes";
    };
    networks."30-wg" = {
      matchConfig.Name = "wg0";
      address = [
        "${config.server.raspi-1.private-ip}/32"
      ];
      linkConfig.RequiredForOnline = "no";
    };

    links."10-eth" = {
      matchConfig.PermanentMACAddress = "b8:27:eb:ab:d4:6b";
      linkConfig.Name = "eth0";
    };

    netdevs."30-wg" = {
      netdevConfig = {
        Name = "wg0";
        Kind = "wireguard";
      };
      wireguardConfig = {
        PrivateKeyFile = config.age.secrets.wireguard_private.path;
      };
      wireguardPeers = [{
          PublicKey = "rW/S+RgN210ExVruYrUi5JKxPURmJBhnzldfbp86mwI=";
          Endpoint = "${config.main-url}:${toString config.ports.exposed.wireguard}";
          AllowedIPs = "${config.server.main-2.private-ip}/32";
          PersistentKeepalive = 25;
        }];
    };
  };
}
