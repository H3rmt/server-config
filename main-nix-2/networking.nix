{ lib, config, ... }: {
  systemd.network = {
    enable = true;
    networks."10-eth" = {
      matchConfig.Name = "eth0";
      dns = config.nameservers ++ config.nameservers-hetzner;
      address = [
        "${config.server."${config.hostnames.main-2}".public-ip}/32"
        "${config.server."${config.hostnames.main-2}".public-ip-v6}/64"
      ];
      routes = [
        { Gateway = "172.31.1.1"; GatewayOnLink = true; }
        { Gateway = "fe80::1"; GatewayOnLink = true; }
      ];
      linkConfig.RequiredForOnline = "yes";
    };
    networks."30-wg" = {
      matchConfig.Name = "wg0";
      address = [
        "${config.server."${config.hostnames.main-2}".private-ip}/24"
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
        }
      ];
    };

    links."10-eth" = {
      matchConfig.PermanentMACAddress = "96:00:03:4d:13:4f";
      linkConfig.Name = "eth0";
    };
  };
}
