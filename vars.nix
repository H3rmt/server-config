{ lib, ... }:
with lib;
{
  vars = {
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
