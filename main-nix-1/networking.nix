{ lib, config, ... }: {
  networking.useNetworkd = true;
  systemd.network = {
    enable = true;
    networks."10-eth" = {
      matchConfig.Name = "eth0";
      dns = config.nameservers;
      address = [
        "128.140.32.233/32"
        "2a01:4f8:c0c:e6fe::1/64"
      ];
      routes = [
        # create default routes for both IPv6 and IPv4
        { routeConfig.Gateway = "fe80::1"; }
        { routeConfig.Gateway = "172.31.1.1"; }
      ];
    };

    networks."20-eth" = {
      matchConfig.Name = "eth1";
      address = [
        "10.0.0.3/32"
      ];
    };
  };
  /**
    2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 96:00:03:46:ee:ef brd ff:ff:ff:ff:ff:ff
    inet 128.140.32.233/32 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 2a01:4f8:c0c:e6fe::1/64 scope global
       valid_lft forever preferred_lft forever
    inet6 fe80::9400:3ff:fe46:eeef/64 scope link
       valid_lft forever preferred_lft forever
    3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc fq_codel state UP group default qlen 1000
    link/ether 86:00:00:88:cc:4a brd ff:ff:ff:ff:ff:ff
    altname enp7s0
    inet 10.0.0.3/32 scope global eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::8400:ff:fe88:f7ce/64 scope link
       valid_lft forever preferred_lft forever
    inet6 fe80::8400:ff:fe88:cc4a/64 scope link proto kernel_ll
       valid_lft forever preferred_lft forever
   */

  # networking = {
  #   nameservers = config.nameservers;
  #   defaultGateway = "172.31.1.1";
  #   defaultGateway6 = {
  #     address = "fe80::1";
  #     interface = "eth0";
  #   };
  #   dhcpcd.enable = false;
  #   usePredictableInterfaceNames = lib.mkForce false;
  #   interfaces = {
  #     eth0 = {
  #       ipv4.addresses = [
  #         { address = "128.140.32.233"; prefixLength = 32; }
  #       ];
  #       ipv6.addresses = [
  #         { address = "2a01:4f8:c0c:e6fe::1"; prefixLength = 64; }
  #         { address = "fe80::9400:3ff:fe46:eeef"; prefixLength = 64; }
  #       ];
  #       ipv4.routes = [{ address = "172.31.1.1"; prefixLength = 32; }];
  #       ipv6.routes = [{ address = "fe80::1"; prefixLength = 128; }];
  #     };
  #     eth1 = {
  #       ipv4.addresses = [
  #         { address = "10.0.0.3"; prefixLength = 32; }
  #       ];
  #       ipv6.addresses = [
  #         { address = "fe80::8400:ff:fe88:f7ce"; prefixLength = 64; }
  #       ];
  #     };
  #   };
  # };
  # services.udev.extraRules = ''
  #   ATTR{address}=="96:00:03:46:ee:ef", NAME="eth0"
  #   ATTR{address}=="86:00:00:88:cc:4a", NAME="eth1"
  # '';
}
