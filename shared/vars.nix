{ lib, ... }: {
  options = {
    nixVersion = lib.mkOption {
      type = lib.types.str;
      description = "Version of NixOS used for System and Homemanager Homes";
    };
    main-url = lib.mkOption {
      type = lib.types.str;
      description = "Root URL for server (h3rmt.zip)";
    };
    main-nix-1-private-ip = lib.mkOption {
      type = lib.types.str;
      description = "IP for server 1";
    };
    main-nix-2-private-ip = lib.mkOption {
      type = lib.types.str;
      description = "IP for server 2";
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
    data-dir = lib.mkOption {
      type = lib.types.str;
      description = "Path for data directory inside a users home";
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
      private = {
        nginx-exporter = lib.mkOption {
          type = lib.types.str;
          description = "Address for Nginx Exporter";
        };
        tor-exporter = lib.mkOption {
          type = lib.types.str;
          description = "Address for Tor Exporter";
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
          node-exporter-1 = lib.mkOption {
            type = lib.types.str;
            description = "Address for Podman Exporter";
          };
          node-exporter-2 = lib.mkOption {
            type = lib.types.str;
            description = "Address for Podman Exporter";
          };
          tor = lib.mkOption {
            type = lib.types.str;
            description = "Address for Podman Exporter";
          };
        };
        node-exporter-1 = lib.mkOption {
          type = lib.types.str;
          description = "Address for Node Exporter on nix-1";
        };
        node-exporter-2 = lib.mkOption {
          type = lib.types.str;
          description = "Address for Node Exporter on nix-2";
        };
        systemd-exporter = {
          reverseproxy = lib.mkOption {
            type = lib.types.str;
            description = "Address for systemd-exporter";
          };
          grafana = lib.mkOption {
            type = lib.types.str;
            description = "Address for systemd-exporter";
          };
          authentik = lib.mkOption {
            type = lib.types.str;
            description = "Address for systemd-exporter";
          };
          snowflake = lib.mkOption {
            type = lib.types.str;
            description = "Address for systemd-exporter";
          };
          nextcloud = lib.mkOption {
            type = lib.types.str;
            description = "Address for systemd-exporter";
          };
          filesharing = lib.mkOption {
            type = lib.types.str;
            description = "Address for systemd-exporter";
          };
          node-exporter-1 = lib.mkOption {
            type = lib.types.str;
            description = "Address for systemd-exporter";
          };
          node-exporter-2 = lib.mkOption {
            type = lib.types.str;
            description = "Address for systemd-exporter";
          };
          tor = lib.mkOption {
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
    main-nix-1-private-ip = "10.0.69.1";
    main-nix-2-private-ip = "10.0.69.2";
    email = "enrico@h3rmt.zip";
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
      };
    };
    address = {
      public = {
        grafana = "${main-nix-2-private-ip}:10000";
        authentik = "${main-nix-2-private-ip}:10001";
        prometheus = "${main-nix-2-private-ip}:10002";
        nextcloud = "${main-nix-1-private-ip}:10003";
        filesharing = "${main-nix-1-private-ip}:10004";
        loki = "${main-nix-2-private-ip}:10005";
        wakapi = "${main-nix-2-private-ip}:10006";
      };
      private = {
        nginx-exporter = "${main-nix-2-private-ip}:20001";
        tor-exporter = "${main-nix-2-private-ip}:20002";
        podman-exporter = {
          reverseproxy = "${main-nix-2-private-ip}:21000";
          grafana = "${main-nix-2-private-ip}:21001";
          authentik = "${main-nix-2-private-ip}:21002";
          snowflake = "${main-nix-2-private-ip}:21003";
          nextcloud = "${main-nix-1-private-ip}:21004";
          filesharing = "${main-nix-1-private-ip}:21005";
          node-exporter-1 = "${main-nix-1-private-ip}:21006";
          node-exporter-2 = "${main-nix-2-private-ip}:21007";
          tor = "${main-nix-2-private-ip}:21008";
        };
        node-exporter-1 = "${main-nix-1-private-ip}:22001";
        node-exporter-2 = "${main-nix-2-private-ip}:22002";
        systemd-exporter = {
          reverseproxy = "${main-nix-2-private-ip}:23000";
          grafana = "${main-nix-2-private-ip}:23001";
          authentik = "${main-nix-2-private-ip}:23002";
          snowflake = "${main-nix-2-private-ip}:23003";
          nextcloud = "${main-nix-1-private-ip}:23004";
          filesharing = "${main-nix-1-private-ip}:23005";
          node-exporter-1 = "${main-nix-1-private-ip}:23006";
          node-exporter-2 = "${main-nix-2-private-ip}:23007";
          tor = "${main-nix-2-private-ip}:23008";
        };
      };
    };
    nameservers = [
      "2a01:4ff:ff00::add:2"
      "2a01:4ff:ff00::add:1"
      "185.12.64.1"
      "185.12.64.2"

      "8.8.8.8"
      "8.8.4.4"
      "2001:4860:4860::8888"
      "2001:4860:4860::8844"
    ];
  };
}
