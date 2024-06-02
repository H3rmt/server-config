{ lib, config, ... }: {
  systemd.network = {
    enable = true;
    networks."10-eth" = {
      matchConfig.Name = "eth0";
      dns = config.nameservers;
      address = [
        "128.140.32.233"
        "2a01:4f8:c0c:e6fe::1/64"
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
        config.server.main-1.private-ip
      ];
      routes = [
        { routeConfig = { Gateway = "172.31.1.1"; Destination = "10.0.69.0/24"; GatewayOnLink = true; }; }
      ];
      linkConfig.RequiredForOnline = "no";
    };
    links."10-eth" = {
      matchConfig.PermanentMACAddress = "96:00:03:46:ee:e";
      linkConfig.Name = "eth0";
    };
    links."20-eth" = {
      matchConfig.PermanentMACAddress = "86:00:00:88:cc:4a";
      linkConfig.Name = "eth1";
    };
  };
}
