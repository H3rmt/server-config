{ lib, ... }: {
  # This file was populated at runtime with the networking
  # details gathered from the active system.
  networking = {
    nameservers = [
      "2a01:4ff:ff00::add:2"
      "2a01:4ff:ff00::add:1"
      "185.12.64.2"
    ];
    defaultGateway = "172.31.1.1";
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address = "128.140.32.233"; prefixLength = 32; }
        ];
        ipv6.addresses = [
          { address = "2a01:4f8:c0c:e6fe::1"; prefixLength = 64; }
          { address = "fe80::9400:3ff:fe46:eeef"; prefixLength = 64; }
        ];
        ipv4.routes = [{ address = "172.31.1.1"; prefixLength = 32; }];
        ipv6.routes = [{ address = "fe80::1"; prefixLength = 128; }];
      };
      eth1 = {
        ipv4.addresses = [
          { address = "10.0.0.3"; prefixLength = 32; }
        ];
        ipv6.addresses = [
          { address = "fe80::8400:ff:fe88:f7ce"; prefixLength = 64; }
        ];
      };
    };
  };
  services.udev.extraRules = ''
    ATTR{address}=="96:00:03:46:ee:ef", NAME="eth0"
    ATTR{address}=="86:00:00:88:cc:4a", NAME="eth1"
  '';
}
