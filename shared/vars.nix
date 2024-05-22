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
      public = {
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
        grafana = lib.mkOption {
          type = lib.types.int;
          description = "HTTP Port for Grafana";
        };
        authentik = lib.mkOption {
          type = lib.types.int;
          description = "HTTP Port for Authnetik";
        };
        prometheus = lib.mkOption {
          type = lib.types.int;
          description = "HTTP Port for Prometheus";
        };
        nextcloud = lib.mkOption {
          type = lib.types.int;
          description = "HTTP Port for Nextcloud";
        };
        filesharing = lib.mkOption {
          type = lib.types.int;
          description = "HTTP Port for Filesharing";
        };
      };
      private = {
        nginx-exporter = lib.mkOption {
          type = lib.types.int;
          description = "HTTP Port for Nginx Exporter";
        };
        podman-exporter = {
          reverseproxy = lib.mkOption {
            type = lib.types.int;
            description = "HTTP Port for Podman Exporter";
          };
          grafana = lib.mkOption {
            type = lib.types.int;
            description = "HTTP Port for Podman Exporter";
          };
          authentik = lib.mkOption {
            type = lib.types.int;
            description = "HTTP Port for Podman Exporter";
          };
          snowflake = lib.mkOption {
            type = lib.types.int;
            description = "HTTP Port for Podman Exporter";
          };
          nextcloud = lib.mkOption {
            type = lib.types.int;
            description = "HTTP Port for Podman Exporter";
          };
          filesharing = lib.mkOption {
            type = lib.types.int;
            description = "HTTP Port for Podman Exporter";
          };
          node-exporter-1 = lib.mkOption {
            type = lib.types.int;
            description = "HTTP Port for Podman Exporter";
          };
          node-exporter-2 = lib.mkOption {
            type = lib.types.int;
            description = "HTTP Port for Podman Exporter";
          };
        };
        node-exporter-1 = lib.mkOption {
          type = lib.types.int;
          description = "HTTP Port for Node Exporter on nix-1";
        };
        node-exporter-2 = lib.mkOption {
          type = lib.types.int;
          description = "HTTP Port for Node Exporter on nix-2";
        };
      };
    };
  };

  config = {
    nixVersion = "24.05";
    main-url = "h3rmt.zip";
    main-nix-1-private-ip = "10.0.69.1";
    main-nix-2-private-ip = "10.0.69.2";
    podman-exporter-version = "v1.11.0";
    nginx-info-page = "nginx_status";
    data-dir = "data";
    sites = {
      authentik = "authentik";
      grafana = "grafana";
      prometheus = "prometheus";
      nextcloud = "nextcloud";
      filesharing = "filesharing";
    };
    ports = {
      public = {
        ssh = 22;
        http = 80;
        https = 443;
        grafana = 10000;
        authentik = 10001;
        prometheus = 10002;
        nextcloud = 10003;
        filesharing = 10004;
      };
      private = {
        nginx-exporter = 20001;
        podman-exporter = {
          reverseproxy = 21000;
          grafana = 21001;
          authentik = 21002;
          snowflake = 21003;
          nextcloud = 21004;
          filesharing = 21005;
          node-exporter-1 = 21006;
          node-exporter-2 = 21007;
        };
        node-exporter-1 = 22001;
        node-exporter-2 = 22002;
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
