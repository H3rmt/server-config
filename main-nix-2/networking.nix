{ lib, config, ... }: {
  networking.useNetworkd = true;
  systemd.network = {
    enable = true;
    networks."10-eth" = {
      matchConfig.MACAddress = "96:00:03:4d:13:4f";
      dns = config.nameservers;
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
      matchConfig.MACAddress = "86:00:00:8a:49:af";
      address = [
        config.main-nix-2-private-ip
      ];
      routes = [
        { routeConfig = { Gateway = "172.31.1.1"; Destination = "10.0.69.0/24"; GatewayOnLink = true; }; }
      ];
      linkConfig.RequiredForOnline = "no";
    };
  };
}
