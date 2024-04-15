{ lib, ... }:
with lib;
{
  options.vars = {
    volume = mkOption {
      type = types.str;
      description = "Mountpoint for shared Volume";
    };
    nixVersion = mkOption {
      type = types.str;
      description = "Version of NixOS used for System and Homemanager Homes";
    };
    main-url = mkOption {
      type = types.str;
      description = "Root URL for server (h3rmt.zip)";
    };
    ports = {
      public = {
        http = mkOption {
          type = types.int;
          description = "HTTP Port for Reverseproxy";
        };
        https = mkOption {
          type = types.int;
          description = "HTTPS Port for Reverseproxy";
        };
        grafana = mkOption {
          type = types.int;
          description = "HTTP Port for Grafana";
        };
        authentik = mkOption {
          type = types.int;
          description = "HTTP Port for Authnetik";
        };
      };
      private = {
        prometheus = mkOption {
          type = types.int;
          description = "HTTP Port for Prometheus (private)";
        };
      };
    };
  };
}
