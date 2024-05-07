{ lib, ... }: {
  networking = {
    nameservers = config.nameservers;
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
          { address = "159.69.206.86"; prefixLength = 32; }
        ];
        ipv6.addresses = [
          { address = "2a01:4f8:1c1b:59c0::1"; prefixLength = 64; }
          { address = "fe80::9400:3ff:fe47:9c93"; prefixLength = 64; }
        ];
        ipv4.routes = [{ address = "172.31.1.1"; prefixLength = 32; }];
        ipv6.routes = [{ address = "fe80::1"; prefixLength = 128; }];
      };
      enp7s0 = {
        ipv4.addresses = [
          { address = "10.0.0.4"; prefixLength = 32; }
        ];
        ipv6.addresses = [
          { address = "fe80::8400:ff:fe88:f7ce"; prefixLength = 64; }
        ];
      };
    };
  };
  services.udev.extraRules = ''
    ATTR{address}=="96:00:03:47:9c:93", NAME="eth0"
    ATTR{address}=="86:00:00:88:f7:ce", NAME="enp7s0"
  '';
}
