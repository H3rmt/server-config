{ lib, ... }:
{
  options = {
    custom = lib.mkOption {
      description = "Custom configuration options.";
      type = lib.types.submodule {
        options = {
          email = lib.mkOption {
            type = lib.types.str;
            description = "Public Email";
          };
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
                  private-ip = lib.mkOption {
                    type = lib.types.str;
                    description = "Private IP for server";
                  };
                  wireguard-public-key = lib.mkOption {
                    type = lib.types.str;
                    description = "Public Key for Wireguard on server";
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
      email = "enrico@h3rmt.dev";
      my-public-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAA/Iusb9djUIvujvzUhkjW7cKysbuNwJPNd/zjmZc+t";
      server = {
        "raspi-1" = {
          private-ip = "10.0.0.101";
          wireguard-public-key = "";
        };
        "ovh-1" = {
          private-ip = "10.0.0.51";
          wireguard-public-key = "xemePTFWc52nX8O1vMp7UJCf/eBIuGkuh/20/9llrmY=";
        };
        "home-1" = {
          private-ip = "10.0.0.102";
          wireguard-public-key = "Z1GnAUQDk05dE6qJZ2TmLIZpPIOnXr9NtPYxwVC3jmw=";
        };
      };
      nameservers-hetzner = [
        "2a01:4ff:ff00::add:2"
        "2a01:4ff:ff00::add:1"
        "185.12.64.1"
        "185.12.64.2"
      ];
      nameservers = [
        "1.1.1.1"
        "8.8.8.8"
        "8.8.4.4"
        "2606:4700:4700::1111"
        "2001:4860:4860::8888"
        "2001:4860:4860::8844"
      ];
    };
  };
}
