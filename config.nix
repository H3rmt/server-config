{ lib, ... }:
{
  options = {
    custom = lib.mkOption {
      description = "Custom configuration options.";
      type = lib.types.submodule {
        options = {
          nameservers = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "Nameservers for DNS";
          };
          nameservers-hetzner = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "Hetzner Nameservers for DNS";
          };
          my-public-key = lib.mkOption {
            type = lib.types.str;
            description = "Public Key for my devices";
          };
          server = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule {
                options = {
                  public-ip-v4 = lib.mkOption {
                    type = lib.types.str;
                    description = "Public IPv4 for server";
                  };
                  public-ip-v6 = lib.mkOption {
                    type = lib.types.str;
                    description = "Public IPv6 for server";
                  };
                };
              }
            );
            description = "Server configurations.";
          };
        };
      };
    };
  };

  config = {
    custom = {
      my-public-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAA/Iusb9djUIvujvzUhkjW7cKysbuNwJPNd/zjmZc+t";
      server = {
        "ovh-1" = {
          public-ip-v4 = "37.187.250.146";
          public-ip-v6 = "2001:41d0:c:292::1";
        };
        "home-2" = {
        };
        "hetzner-1" = {
          public-ip-v4 = "167.235.249.79";
          public-ip-v6 = "2a01:4f8:c014:532f::1";
        };
      };
      nameservers-hetzner = [
        "185.12.64.1"
        "2a01:4ff:ff00::add:1"
        "185.12.64.2"
        "2a01:4ff:ff00::add:2"
      ];
      nameservers = [
        "1.1.1.1"
        "2606:4700:4700::1111"
        "8.8.4.4"
        "2001:4860:4860::8844"
      ];
    };
  };
}
