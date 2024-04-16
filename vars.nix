{ lib, ... }: {
  options = {
    volume = lib.mkOption {
      type = lib.types.str;
      description = "Mountpoint for shared Volume";
    };
    nixVersion = lib.mkOption {
      type = lib.types.str;
      description = "Version of NixOS used for System and Homemanager Homes";
    };
    main-url = lib.mkOption {
      type = lib.types.str;
      description = "Root URL for server (h3rmt.zip)";
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
      };
      private = {
        prometheus = lib.mkOption {
          type = lib.types.int;
          description = "HTTP Port for Prometheus (private)";
        };
      };
    };
  };

  config = {
    nixVersion = "23.05";
    volume = "/mnt/volume-nbg1-1";
    main-url = "h3rmt.zip";
    ports = {
      public = {
        http = 80;
        https = 443;
        grafana = 10000;
        authentik = 10001;
      };
      private = {
        prometheus = 20000;
      };
    };
  };
}
