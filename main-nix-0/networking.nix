{ lib, config, ... }: {
  imports = [
    ./vars.nix
  ];
  networking = {
    nameservers = [
      "2a01:4ff:ff00::add:1"
      "2a01:4ff:ff00::add:2"
      "185.12.64.1"
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
          { address = config.ipv4; prefixLength = 32; }
        ];
        ipv6.addresses = [
          { address = config.ipv6; prefixLength = 64; }
          { address = "fe80::9400:3ff:fe30:f442"; prefixLength = 64; }
        ];
        ipv4.routes = [{ address = "172.31.1.1"; prefixLength = 32; }];
        ipv6.routes = [{ address = "fe80::1"; prefixLength = 128; }];
      };

    };
  };
  services.udev.extraRules = ''
    ATTR{address}=="96:00:03:30:f4:42", NAME="eth0"
  '';
}
