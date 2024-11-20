{ lib, config, ... }: {
  options = {
    nixVersion = lib.mkOption {
      type = lib.types.str;
      description = "Version of NixOS used for System and Homemanager Homes";
    };
    main-url = lib.mkOption {
      type = lib.types.str;
      description = "Root URL for server (h3rmt.zip)";
    };
    podman-exporter-version = lib.mkOption {
      type = lib.types.str;
      description = "Image Version for Podman-exporter";
    };
    nginx-info-page = lib.mkOption {
      type = lib.types.str;
      description = "Path for site with debug info on nginx";
    };
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
    data-dir = lib.mkOption {
      type = lib.types.str;
      description = "Path for data directory inside a users home";
    };
    backup-dir = lib.mkOption {
      type = lib.types.str;
      description = "Path for backups directory from this server";
    };
    backup-user-prefix = lib.mkOption {
      type = lib.types.str;
      description = "User for borg-backup";
    };
    exporter-user-prefix = lib.mkOption {
      type = lib.types.str;
      description = "User for exporters (node-exporter, promtail, etc.)";
    };
    my-public-key = lib.mkOption {
      type = lib.types.str;
      description = "Public Key for my devices";
    };
    hostnames = {
      main-1 = lib.mkOption {
        type = lib.types.str;
        description = "Hostname for server 1";
      };
      main-2 = lib.mkOption {
        type = lib.types.str;
        description = "Hostname for server 2";
      };
      raspi-1 = lib.mkOption {
        type = lib.types.str;
        description = "Hostname for raspi 1";
      };
    };
    server = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          public-ip = lib.mkOption {
            type = lib.types.str;
            description = "Public IP for server 1";
          };
          private-ip = lib.mkOption {
            type = lib.types.str;
            description = "Private IP for server 1";
          };
          root-public-key = lib.mkOption {
            type = lib.types.str;
            description = "Public Key for root on server 1";
          };
          wireguard-public-key = lib.mkOption {
            type = lib.types.str;
            description = "Public Key for Wireguard on server 1";
          };
          backup-users = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "List of users to backup on server 1 (/home/$username/config.data-dir)";
          };
          backup-trigger-minutes = lib.mkOption {
            type = lib.types.int;
            description = "Minutes to wait before triggering backup on server 1";
          };
        };
      });
      description = "Server configurations.";
    };
    sites = {
      authentik = lib.mkOption {
        type = lib.types.str;
        description = "Subdomain for authentik";
      };
      grafana = lib.mkOption {
        type = lib.types.str;
        description = "Subdomain for grafana";
      };
      prometheus = lib.mkOption {
        type = lib.types.str;
        description = "Subdomain for prometheus";
      };
      nextcloud = lib.mkOption {
        type = lib.types.str;
        description = "Subdomain for nextcloud";
      };
      filesharing = lib.mkOption {
        type = lib.types.str;
        description = "Subdomain for filesharing";
      };
      wakapi = lib.mkOption {
        type = lib.types.str;
        description = "Subdomain for wakapi";
      };
    };
    ports = {
      exposed = {
        ssh = lib.mkOption {
          type = lib.types.int;
          description = "HTTP Port for SSH";
        };
        http = lib.mkOption {
          type = lib.types.int;
          description = "HTTP Port for Reverseproxy";
        };
        https = lib.mkOption {
          type = lib.types.int;
          description = "HTTPS Port for Reverseproxy";
        };
        tor-middle = lib.mkOption {
          type = lib.types.int;
          description = "Port for Tor Middle relay";
        };
        tor-middle-dir = lib.mkOption {
          type = lib.types.int;
          description = "Dir Port for Tor Middle relay";
        };
        tor-bridge = lib.mkOption {
          type = lib.types.int;
          description = "Port for Tor Bridge relay";
        };
        tor-bridge-pt = lib.mkOption {
          type = lib.types.int;
          description = "Pt Port for Tor Bridge relay";
        };
        wireguard = lib.mkOption {
          type = lib.types.int;
          description = "Port for Wireguard";
        };
      };
    };
    address = {
      public = {
        grafana = lib.mkOption {
          type = lib.types.str;
          description = "Address for Grafana";
        };
        authentik = lib.mkOption {
          type = lib.types.str;
          description = "Address for Authnetik";
        };
        prometheus = lib.mkOption {
          type = lib.types.str;
          description = "Address for Prometheus";
        };
        nextcloud = lib.mkOption {
          type = lib.types.str;
          description = "Address for Nextcloud";
        };
        filesharing = lib.mkOption {
          type = lib.types.str;
          description = "Address for Filesharing";
        };
        loki = lib.mkOption {
          type = lib.types.str;
          description = "Address for Loki";
        };
        wakapi = lib.mkOption {
          type = lib.types.str;
          description = "Address for Wakapi";
        };
      };
      private = {
        nginx-exporter = lib.mkOption {
          type = lib.types.str;
          description = "Address for Nginx Exporter";
        };
        tor-exporter = lib.mkOption {
          type = lib.types.str;
          description = "Address for Tor Exporter";
        };
        tor-exporter-bridge = lib.mkOption {
          type = lib.types.str;
          description = "Address for Tor Bridge Exporter";
        };
        snowflake-exporter-1 = lib.mkOption {
          type = lib.types.str;
          description = "Address for Snowflake Exporter 1";
        };
        snowflake-exporter-2 = lib.mkOption {
          type = lib.types.str;
          description = "Address for Snowflake Exporter 2";
        };
        podman-exporter = {
          reverseproxy = lib.mkOption {
            type = lib.types.str;
            description = "Address for Podman Exporter";
          };
          grafana = lib.mkOption {
            type = lib.types.str;
            description = "Address for Podman Exporter";
          };
          authentik = lib.mkOption {
            type = lib.types.str;
            description = "Address for Podman Exporter";
          };
          snowflake = lib.mkOption {
            type = lib.types.str;
            description = "Address for Podman Exporter";
          };
          nextcloud = lib.mkOption {
            type = lib.types.str;
            description = "Address for Podman Exporter";
          };
          filesharing = lib.mkOption {
            type = lib.types.str;
            description = "Address for Podman Exporter";
          };
          "${config.exporter-user-prefix}-${config.hostnames.main-1}" = lib.mkOption {
            type = lib.types.str;
            description = "Address for Podman Exporter";
          };
          "${config.exporter-user-prefix}-${config.hostnames.main-2}" = lib.mkOption {
            type = lib.types.str;
            description = "Address for Podman Exporter";
          };
          tor = lib.mkOption {
            type = lib.types.str;
            description = "Address for Podman Exporter";
          };
          wakapi = lib.mkOption {
            type = lib.types.str;
            description = "Address for Podman Exporter";
          };
          bridge = lib.mkOption {
            type = lib.types.str;
            description = "Address for Podman Exporter";
          };
          "${config.exporter-user-prefix}-${config.hostnames.raspi-1}" = lib.mkOption {
            type = lib.types.str;
            description = "Address for Podman Exporter";
          };
        };
        node-exporter = {
          "${config.exporter-user-prefix}-${config.hostnames.main-1}" = lib.mkOption {
            type = lib.types.str;
            description = "Address for Node Exporter on nix-1";
          };
          "${config.exporter-user-prefix}-${config.hostnames.main-2}" = lib.mkOption {
            type = lib.types.str;
            description = "Address for Node Exporter on nix-2";
          };
          "${config.exporter-user-prefix}-${config.hostnames.raspi-1}" = lib.mkOption {
            type = lib.types.str;
            description = "Address for Node Exporter on raspi-1";
          };
        };
        systemd-exporter = {
          reverseproxy = lib.mkOption {
            type = lib.types.str;
            description = "Address for systemd-exporter";
          };
          "${config.hostnames.main-1}" = lib.mkOption {
            type = lib.types.str;
            description = "Address for systemd-exporter";
          };
          "${config.hostnames.main-2}" = lib.mkOption {
            type = lib.types.str;
            description = "Address for systemd-exporter";
          };
          "${config.hostnames.raspi-1}" = lib.mkOption {
            type = lib.types.str;
            description = "Address for systemd-exporter";
          };
        };
        wireguard = {
          "wireguard-exporter-${config.hostnames.main-1}" = lib.mkOption {
            type = lib.types.str;
            description = "Address for Wireguard Exporter";
          };
          "wireguard-exporter-${config.hostnames.main-2}" = lib.mkOption {
            type = lib.types.str;
            description = "Address for Wireguard Exporter";
          };
          "wireguard-exporter-${config.hostnames.raspi-1}" = lib.mkOption {
            type = lib.types.str;
            description = "Address for Wireguard Exporter";
          };
        };
      };
    };
  };

  config = rec {
    nixVersion = "24.05";
    main-url = "h3rmt.zip";
    podman-exporter-version = "v1.11.0";
    nginx-info-page = "nginx_status";
    data-dir = "data";
    backup-dir = "backups";
    email = "enrico@h3rmt.zip";
    backup-user-prefix = "borg-backup";
    exporter-user-prefix = "exporter";
    my-public-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAA/Iusb9djUIvujvzUhkjW7cKysbuNwJPNd/zjmZc+t";
    hostnames = {
      main-1 = "main-nix-1";
      main-2 = "main-nix-2";
      raspi-1 = "raspi-1";
    };
    server = {
      "${config.hostnames.main-1}" = {
        public-ip = "128.140.32.233";
        private-ip = "10.0.69.1";
        root-public-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICKIpoY7xkKbUMJ1/Fg1jPu1jwQzfXgjvybcsXnbI0eM";
        wireguard-public-key = "6vInhWMq9wX1AaWkk685kWRQossUZm8D2kUQpfsWW1E=";
        backup-users = [
          "bridge"
          "filesharing"
          "nextcloud"
        ];
        backup-trigger-minutes = 10;
      };
      "${config.hostnames.main-2}" = {
        public-ip = "159.69.206.86";
        private-ip = "10.0.69.2";
        root-public-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDAz2IRRlU5CN8TRnHnHD98R5CWSGHQBg9hxqeYARdoK";
        wireguard-public-key = "rW/S+RgN210ExVruYrUi5JKxPURmJBhnzldfbp86mwI=";
        backup-users = [
          "authentik"
          "grafana"
          "reverseproxy"
          "tor"
          "wakapi"
        ];
        backup-trigger-minutes = 15;
      };
      "${config.hostnames.raspi-1}" = {
        public-ip = "";
        private-ip = "10.0.69.11";
        root-public-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIChc0OADBHo5eqE4tcVHglCGzUvHSTZ6LeC0RcGQ9V6C";
        wireguard-public-key = "gj3o5IT+uLrERp63JV/NuDg2s/ggclgQfBoZyBW+jk0=";
        backup-users = [

        ];
        backup-trigger-minutes = 20;
      };
    };
    sites = {
      authentik = "authentik";
      grafana = "grafana";
      prometheus = "prometheus";
      nextcloud = "nextcloud";
      filesharing = "filesharing";
      wakapi = "wakapi";
    };
    ports = {
      exposed = {
        ssh = 22;
        http = 80;
        https = 443;
        tor-middle = 9000;
        tor-middle-dir = 9030;
        tor-bridge = 9100;
        tor-bridge-pt = 9140;
        wireguard = 51820;
      };
    };
    address = {
      public = {
        grafana = "${server."${hostnames.main-2}".private-ip}:10000";
        authentik = "${server."${hostnames.main-2}".private-ip}:10001";
        prometheus = "${server."${hostnames.main-2}".private-ip}:10002";
        nextcloud = "${server."${hostnames.main-1}".private-ip}:10003";
        filesharing = "${server."${hostnames.main-1}".private-ip}:10004";
        loki = "${server."${hostnames.main-2}".private-ip}:10005";
        wakapi = "${server."${hostnames.main-2}".private-ip}:10006";
      };
      private = {
        nginx-exporter = "${server."${hostnames.main-2}".private-ip}:20001";
        tor-exporter = "${server."${hostnames.main-2}".private-ip}:20002";
        tor-exporter-bridge = "${server."${hostnames.main-1}".private-ip}:20003";
        snowflake-exporter-1 = "${server."${hostnames.main-1}".private-ip}:20004";
        snowflake-exporter-2 = "${server."${hostnames.main-1}".private-ip}:20005";
        podman-exporter = {
          reverseproxy = "${server."${hostnames.main-2}".private-ip}:21000";
          grafana = "${server."${hostnames.main-2}".private-ip}:21001";
          authentik = "${server."${hostnames.main-2}".private-ip}:21002";
          snowflake = "${server."${hostnames.main-1}".private-ip}:21003";
          nextcloud = "${server."${hostnames.main-1}".private-ip}:21004";
          filesharing = "${server."${hostnames.main-1}".private-ip}:21005";
          "${exporter-user-prefix}-${hostnames.main-1}" = "${server."${hostnames.main-1}".private-ip}:21006";
          "${exporter-user-prefix}-${hostnames.main-2}" = "${server."${hostnames.main-2}".private-ip}:21007";
          tor = "${server."${hostnames.main-2}".private-ip}:21008";
          wakapi = "${server."${hostnames.main-2}".private-ip}:21009";
          bridge = "${server."${hostnames.main-1}".private-ip}:21010";
          "${exporter-user-prefix}-${hostnames.raspi-1}" = "${server."${hostnames.raspi-1}".private-ip}:21011";
        };
        node-exporter = {
          "${exporter-user-prefix}-${hostnames.main-1}" = "${server."${hostnames.main-1}".private-ip}:22001";
          "${exporter-user-prefix}-${hostnames.main-2}" = "${server."${hostnames.main-2}".private-ip}:22002";
          "${exporter-user-prefix}-${hostnames.raspi-1}" = "${server."${hostnames.raspi-1}".private-ip}:22003";
        };
        systemd-exporter = {
          reverseproxy = "${server."${hostnames.main-2}".private-ip}:23000";
          "${config.hostnames.main-1}" = "${server."${hostnames.main-1}".private-ip}:23001";
          "${config.hostnames.main-2}" = "${server."${hostnames.main-2}".private-ip}:23002";
          "${config.hostnames.raspi-1}" = "${server."${hostnames.raspi-1}".private-ip}:23003";
        };
        wireguard = {
          "wireguard-exporter-${hostnames.main-1}" = "${server."${hostnames.main-1}".private-ip}:24000";
          "wireguard-exporter-${hostnames.main-2}" = "${server."${hostnames.main-2}".private-ip}:24002";
          "wireguard-exporter-${hostnames.raspi-1}" = "${server."${hostnames.raspi-1}".private-ip}:24003";
        };
      };
    };
    nameservers-hetzner = [
      "2a01:4ff:ff00::add:2"
      "2a01:4ff:ff00::add:1"
      "185.12.64.1"
      "185.12.64.2"
    ];
    nameservers = [
      "8.8.8.8"
      "8.8.4.4"
      "2001:4860:4860::8888"
      "2001:4860:4860::8844"
    ];
  };
}
