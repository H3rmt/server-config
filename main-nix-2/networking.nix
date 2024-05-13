{ lib, config, ... }: {
  networking.useNetworkd = true;
  systemd.network = {
    enable = true;
    networks."10-eth" = {
      matchConfig.Name = "enp1s0";
      dns = config.nameservers;
      address = [
        "159.69.206.86/32"
        "2a01:4f8:1c1b:59c0::1/64"
      ];
      routes = [
        { routeConfig = { Gateway = "fe80::1"; GatewayOnLink = true; }; }
        { routeConfig = { Gateway = "172.31.1.1"; GatewayOnLink = true; }; }
        # ip route add default via 172.31.1.1 onlink dev eth0
      ];
      linkConfig.RequiredForOnline = "yes";
    };

    networks."20-eth" = {
      matchConfig.Name = "enp7s0";
      address = [
        "10.0.69.2/32"
      ];
      linkConfig.RequiredForOnline = "no";
    };
  };
}
