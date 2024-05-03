{ age, clib }: { lib, config, home, pkgs, inputs, ... }:
let
  volume-prefix = "${config.volume}/Snowflake";

  PODNAME = "snowflake_pod";
  SNOWFLAKE_VERSION = "v2.8.1";

  exporter = clib.create-podman-exporter "snowflake" "${PODNAME}";
in
{
  imports = [
    ../vars.nix
    ../zsh.nix
  ];
  home.stateVersion = config.nixVersion;
  home.sessionVariables.XDG_RUNTIME_DIR = "/run/user/$UID";

  home.file = clib.create-files config.home.homeDirectory {
    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${PODNAME} \
            -p ${exporter.port} \
            --network pasta:-a,10.0.0.1

        podman run --name=snowflake-proxy-1 -d --pod=${PODNAME} \
            --network=host \
            --restart unless-stopped \
            docker.io/thetorproject/snowflake-proxy:${SNOWFLAKE_VERSION} \
            -ephemeral-ports-range 20000:60000 -unsafe-logging -summary-interval 12h0m0s

        podman run --name=snowflake-proxy-2 -d --pod=${PODNAME} \
            --network=host \
            --restart unless-stopped \
            docker.io/thetorproject/snowflake-proxy:${SNOWFLAKE_VERSION} \
            -ephemeral-ports-range 20000:60000 -unsafe-logging -summary-interval 12h0m0s

        ${exporter.run}
      '';
    };

    "down.sh" = {
      executable = true;
      text = ''
        podman stop -t 10 snowflake-proxy-1
        podman stop -t 10 snowflake-proxy-2
        podman rm snowflake-proxy-1 snowflake-proxy-2
        ${exporter.stop}
        podman pod rm ${PODNAME}
      '';
    };
  };
}
