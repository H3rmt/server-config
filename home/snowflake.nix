{ lib
, config
, home
, pkgs
, inputs
, ...
}:
let
  volume-prefix = "${config.volume}/Authentik";
  clib = import ../funcs.nix { inherit lib; inherit config; };

  SNOWFLAKE_VERSION = "v2.8.1";
in
{
  imports = [
    ../vars.nix
    ../zsh.nix
  ];
  home.stateVersion = config.nixVersion;
  home.sessionVariables.XDG_RUNTIME_DIR = "/run/user/$UID";

  home.file = clib.create-files {
    "compose.yml" = {
      noLink = true;
      text = ''
        services:
          snowflake-proxy-1:
            network_mode: host
            image: docker.io/thetorproject/snowflake-proxy:${SNOWFLAKE_VERSION}
            container_name: snowflake-proxy-1
            restart: unless-stopped
            command: [ "-ephemeral-ports-range", "30000:60000", "-unsafe-logging", "-summary-interval", "12h0m0s" ]

          snowflake-proxy-2:
            network_mode: host
            image: docker.io/thetorproject/snowflake-proxy:${SNOWFLAKE_VERSION}
            container_name: snowflake-proxy-2
            restart: unless-stopped
            command: [ "-ephemeral-ports-range", "30000:60000", "-unsafe-logging", "-summary-interval", "12h0m0s" ]
      '';
    };
  };
}
