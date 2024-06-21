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
    server = {
      main-1 = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "Hostname for server 1";
        };
        private-ip = lib.mkOption {
          type = lib.types.str;
          description = "Private IP for server 1";
        };
        public-key = lib.mkOption {
          type = lib.types.str;
          description = "Public Key for server 1";
        };
        public-key-borg = lib.mkOption {
          type = lib.types.str;
          description = "Public Key for borg-backup on server 1";
        };
        public-key-wg = lib.mkOption {
          type = lib.types.str;
          description = "Public Key for Wireguard on server 1";
        };
      };
      main-2 = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "Hostname for server 2";
        };
        private-ip = lib.mkOption {
          type = lib.types.str;
          description = "Private IP for server 2";
        };
        public-key = lib.mkOption {
          type = lib.types.str;
          description = "Public Key for server 2";
        };
        public-key-borg = lib.mkOption {
          type = lib.types.str;
          description = "Public Key for borg-backup on server 2";
        };
        public-key-wg = lib.mkOption {
          type = lib.types.str;
          description = "Public Key for Wireguard on server 2";
        };
      };
      raspi-1 = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "Hostname for raspi 1";
        };
        private-ip = lib.mkOption {
          type = lib.types.str;
          description = "Private IP for raspi 1";
        };
        public-key = lib.mkOption {
          type = lib.types.str;
          description = "Public Key for raspi 1";
        };
        public-key-borg = lib.mkOption {
          type = lib.types.str;
          description = "Public Key for borg-backup on raspi 1";
        };
        public-key-wg = lib.mkOption {
          type = lib.types.str;
          description = "Public Key for Wireguard on raspi 1";
        };
      };
    };
    backups = {
      "${config.server.main-1.name}" = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "List of directories to backup on server 1";
      };
      "${config.server.main-2.name}" = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "List of directories to backup on server 2";
      };
      "${config.server.raspi-1.name}" = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "List of directories to backup on raspi 1";
      };
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
        wireguard-exporter = lib.mkOption {
          type = lib.types.str;
          description = "Address for Wireguard Exporter";
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
          "${config.exporter-user-prefix}-${config.server.main-1.name}" = lib.mkOption {
            type = lib.types.str;
            description = "Address for Podman Exporter";
          };
          "${config.exporter-user-prefix}-${config.server.main-2.name}" = lib.mkOption {
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
          "${config.exporter-user-prefix}-${config.server.raspi-1.name}" = lib.mkOption {
            type = lib.types.str;
            description = "Address for Podman Exporter";
          };
        };
        node-exporter = {
          "${config.exporter-user-prefix}-${config.server.main-1.name}" = lib.mkOption {
            type = lib.types.str;
            description = "Address for Node Exporter on nix-1";
          };
          "${config.exporter-user-prefix}-${config.server.main-2.name}" = lib.mkOption {
            type = lib.types.str;
            description = "Address for Node Exporter on nix-2";
          };
          "${config.exporter-user-prefix}-${config.server.raspi-1.name}" = lib.mkOption {
            type = lib.types.str;
            description = "Address for Node Exporter on raspi-1";
          };
        };
        systemd-exporter = {
          reverseproxy = lib.mkOption {
            type = lib.types.str;
            description = "Address for systemd-exporter";
          };
          "${config.backup-user-prefix}-${config.server.main-1.name}" = lib.mkOption {
            type = lib.types.str;
            description = "Address for systemd-exporter";
          };
          "${config.backup-user-prefix}-${config.server.main-2.name}" = lib.mkOption {
            type = lib.types.str;
            description = "Address for systemd-exporter";
          };
          "${config.backup-user-prefix}-${config.server.raspi-1.name}" = lib.mkOption {
            type = lib.types.str;
            description = "Address for systemd-exporter";
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
    email = "enrico@h3rmt.zip";
    backup-user-prefix = "borg-backup";
    exporter-user-prefix = "exporter";
    my-public-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAA/Iusb9djUIvujvzUhkjW7cKysbuNwJPNd/zjmZc+t";
    server = {
      main-1 = {
        name = "main-nix-1";
        private-ip = "10.0.69.1";
        public-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICKIpoY7xkKbUMJ1/Fg1jPu1jwQzfXgjvybcsXnbI0eM";
        public-key-borg = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIClcB52PQnVTVdujdIxmhmWedD9xL8X2yqK10VR6L0eg";
        public-key-wg = "6vInhWMq9wX1AaWkk685kWRQossUZm8D2kUQpfsWW1E=";
      };
      main-2 = {
        name = "main-nix-2";
        private-ip = "10.0.69.2";
        public-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDAz2IRRlU5CN8TRnHnHD98R5CWSGHQBg9hxqeYARdoK";
        public-key-borg = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHvWPgmouh5v2ublt6mXAXBoLQZm9GUWtk9iTYPZMOxF";
        public-key-wg = "rW/S+RgN210ExVruYrUi5JKxPURmJBhnzldfbp86mwI=";
      };
      raspi-1 = {
        name = "raspi-1";
        private-ip = "10.0.69.11";
        public-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIChc0OADBHo5eqE4tcVHglCGzUvHSTZ6LeC0RcGQ9V6C";
        public-key-borg = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAxDL2Ms3vSJia24a2rSdFdw2t/vTGaOYcrijjMHhOpU";
        public-key-wg = "gj3o5IT+uLrERp63JV/NuDg2s/ggclgQfBoZyBW+jk0=";
      };
    };
    backups = {
      "${config.server.main-1.name}" = [
        "/home/bridge/${config.data-dir}"
        "/home/filesharing/${config.data-dir}"
        "/home/nextcloud/${config.data-dir}"
      ];
      "${config.server.main-2.name}" = [
        "/home/authentik/${config.data-dir}"
        "/home/grafana/${config.data-dir}"
        "/home/reverseproxy/${config.data-dir}"
        "/home/tor/${config.data-dir}"
        "/home/wakapi/${config.data-dir}"
      ];
      "${config.server.raspi-1.name}" = [
      ];
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
        grafana = "${server.main-2.private-ip}:10000";
        authentik = "${server.main-2.private-ip}:10001";
        prometheus = "${server.main-2.private-ip}:10002";
        nextcloud = "${server.main-1.private-ip}:10003";
        filesharing = "${server.main-1.private-ip}:10004";
        loki = "${server.main-2.private-ip}:10005";
        wakapi = "${server.main-2.private-ip}:10006";
      };
      private = {
        nginx-exporter = "${server.main-2.private-ip}:20001";
        tor-exporter = "${server.main-2.private-ip}:20002";
        tor-exporter-bridge = "${server.main-1.private-ip}:20003";
        snowflake-exporter-1 = "${server.main-1.private-ip}:20004";
        snowflake-exporter-2 = "${server.main-1.private-ip}:20005";
        wireguard-exporter = "${server.main-2.private-ip}:20006";
        podman-exporter = {
          reverseproxy = "${server.main-2.private-ip}:21000";
          grafana = "${server.main-2.private-ip}:21001";
          authentik = "${server.main-2.private-ip}:21002";
          snowflake = "${server.main-1.private-ip}:21003";
          nextcloud = "${server.main-1.private-ip}:21004";
          filesharing = "${server.main-1.private-ip}:21005";
          "${exporter-user-prefix}-${server.main-1.name}" = "${server.main-1.private-ip}:21006";
          "${exporter-user-prefix}-${server.main-2.name}" = "${server.main-2.private-ip}:21007";
          tor = "${server.main-2.private-ip}:21008";
          wakapi = "${server.main-2.private-ip}:21009";
          bridge = "${server.main-1.private-ip}:21010";
          "${exporter-user-prefix}-${server.raspi-1.name}" = "${server.raspi-1.private-ip}:21011";
        };
        node-exporter = {
          "${exporter-user-prefix}-${server.main-1.name}" = "${server.main-1.private-ip}:22001";
          "${exporter-user-prefix}-${server.main-2.name}" = "${server.main-2.private-ip}:22002";
          "${exporter-user-prefix}-${server.raspi-1.name}" = "${server.raspi-1.private-ip}:22003";
        };
        systemd-exporter = {
          reverseproxy = "${server.main-2.private-ip}:23000";
          "${backup-user-prefix}-${server.main-1.name}" = "${server.main-1.private-ip}:23001";
          "${backup-user-prefix}-${server.main-2.name}" = "${server.main-2.private-ip}:23002";
          "${backup-user-prefix}-${server.raspi-1.name}" = "${server.raspi-1.private-ip}:23003";
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
