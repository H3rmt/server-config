{ lib, config, ... }: {
  systemd.network = {
    enable = true;
    networks."10-eth" = {
      matchConfig.Name = "eth0";
      dns = config.nameservers;
      address = [
        "192.168.187.45"
      ];
      routes = [
        { routeConfig = { Gateway = "192.168.187.1"; GatewayOnLink = true; }; }
      ];
      linkConfig.RequiredForOnline = "yes";
    };

    # networks."20-eth" = {
    #   matchConfig.Name = "eth1";
    #   address = [
    #     config.server.main-1.private-ip
    #   ];
    #   routes = [
    #     { routeConfig = { Gateway = "172.31.1.1"; Destination = "10.0.69.0/24"; GatewayOnLink = true; }; }
    #   ];
    #   linkConfig.RequiredForOnline = "no";
    # };
    links."10-eth" = {
      matchConfig.PermanentMACAddress = "b8:27:eb:ab:d4:6b";
      linkConfig.Name = "eth0";
    };
    # links."20-eth" = {
    #   matchConfig.PermanentMACAddress = "86:00:00:88:cc:4a";
    #   linkConfig.Name = "eth1";
    # };
  };
}
