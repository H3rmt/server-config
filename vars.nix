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
    podman-exporter-version = lib.mkOption {
      type = lib.types.str;
      description = "Image Version for Podman-exporter";
    };
    nginx-info-page = lib.mkOption {
      type = lib.types.str;
      description = "Path for site with debug info on nginx";
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
        nginx-status = lib.mkOption {
          type = lib.types.int;
          description = "HTTP Port for Nginx /nginx-status Endpoint";
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
        };
      };
    };
  };

  config = {
    nixVersion = "24.05";
    main-url = "h3rmt.zip";
    podman-exporter-version = "v1.11.0";
    nginx-info-page = "nginx_status";
    sites = {
      authentik = "authentik";
      grafana = "grafana";
      prometheus = "prometheus";
      nextcloud = "nextcloud";
      filesharing = "filesharing";
    };
    ports = {
      public = {
        http = 80;
        https = 443;
        grafana = 10000;
        authentik = 10001;
        prometheus = 10002;
        nextcloud = 10003;
        filesharing = 10004;
      };
      private = {
        nginx-status = 20001;
        podman-exporter = {
          reverseproxy = 21000;
          grafana = 21001;
          authentik = 21002;
          snowflake = 21003;
          nextcloud = 21004;
          filesharing = 21005;
        };
      };
    };
  };
}
