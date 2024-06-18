{ lib, config, ... }: {
  systemd.network = {
    enable = true;
    networks."10-eth" = {
      matchConfig.Name = "eth0";
      dns = config.nameservers ++ config.nameservers-hetzner;
      address = [
        "159.69.206.86"
        "2a01:4f8:1c1b:59c0::1/64"
      ];
      routes = [
        { routeConfig = { Gateway = "fe80::1"; GatewayOnLink = true; }; }
        { routeConfig = { Gateway = "172.31.1.1"; GatewayOnLink = true; }; }
      ];
      linkConfig.RequiredForOnline = "yes";
    };
    networks."20-eth" = {
      matchConfig.Name = "eth1";
      address = [
        config.server.main-2.private-ip
      ];
      routes = [
        { routeConfig = { Gateway = "172.31.1.1"; Destination = "10.0.69.0/24"; GatewayOnLink = true; }; }
      ];
      linkConfig.RequiredForOnline = "no";
    };
    networks."30-wg" = {
      matchConfig.Name = "wg0";
      address = [
        config.server.raspi-1.private-ip
      ];
      linkConfig.RequiredForOnline = "no";
      networkConfig = {
        IPMasquerade = "ipv4";
        IPForward = true;
      };
    };
    links."10-eth" = {
      matchConfig.PermanentMACAddress = "96:00:03:4d:13:4f";
      linkConfig.Name = "eth0";
    };
    links."20-eth" = {
      matchConfig.PermanentMACAddress = "86:00:00:8a:49:af";
      linkConfig.Name = "eth1";
    };
    netdevs."30-wg" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "wg0";
        MTUBytes = "1300";
      };
      wireguardConfig = {
        PrivateKeyFile = config.age.wireguard_private.path;
        ListenPort = config.ports.exposed.wireguard;
      };
      wireguardPeers = [
        {
          wireguardPeerConfig = {
            PublicKey = "L4msD0mEG2ctKDtaMJW2y3cs1fT2LBRVV7iVlWZ2nZc=";
            AllowedIPs = [ config.server.raspi-1.private-ip ];
          };
        }
      ];
    };
  };
}
