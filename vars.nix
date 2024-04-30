{ lib, ... }: {
  options = {
    volume = lib.mkOption {
      type = lib.types.str;
      description = "Mountpoint for shared Volume";
    };
    ipv4 = lib.mkOption {
      type = lib.types.str;
      description = "IPv4 Of Server";
    };
    ipv6 = lib.mkOption {
      type = lib.types.str;
      description = "IPv4 Of Server";
    };
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
      };
      private = {
        nginx-status = lib.mkOption {
          type = lib.types.int;
          description = "HTTP Port for Nginx /nginx-status Endpoint";
        };
        podman-exporter = {
          nginx = lib.mkOption {
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
        };
      };
    };
  };

  config = {
    nixVersion = "24.05";
    ipv4 = "49.13.224.56";
    ipv6 = "2a01:4f8:1c1b:54c0::1";
    volume = "/mnt/volume-nbg1-1";
    main-url = "h3rmt.zip";
    podman-exporter-version = "v1.11.0";
    ports = {
      public = {
        http = 80;
        https = 443;
        grafana = 10000;
        authentik = 10001;
        prometheus = 10002;
      };
      private = {
        nginx-status = 20001;
        podman-exporter = {
          nginx = 21000;
          grafana = 21001;
          authentik = 21002;
          snowflake = 21003;
        };
      };
    };
  };
}
