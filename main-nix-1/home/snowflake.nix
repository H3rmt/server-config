{ age, clib }: { lib, config, home, pkgs, inputs, ... }:
let
  SNOWFLAKE_VERSION = "v2.8.1";
in
{
  imports = [
    ../../shared/usr.nix
  ];

  home.file = clib.create-files config.home.homeDirectory {
    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${config.pod-name} --userns=keep-id \
            -p ${config.address.private.snowflake-exporter-1}:3000 \
            -p ${config.address.private.snowflake-exporter-2}:3001 \
            -p ${config.exporter.port} \
            --network pasta:-a,172.16.0.1

        podman run --name=snowflake-proxy-1 -d --pod=${config.pod-name} \
            --restart on-failure:10 \
            -u $UID:$GID \
            docker.io/thetorproject/snowflake-proxy:${SNOWFLAKE_VERSION} \
            -summary-interval 6h0m0s -metrics -metricsPort 3000 -verbose -unsafe-logging 

        podman run --name=snowflake-proxy-2 -d --pod=${config.pod-name} \
            --restart on-failure:10 \
            -u $UID:$GID \
            docker.io/thetorproject/snowflake-proxy:${SNOWFLAKE_VERSION} \
            -summary-interval 6h0m0s -metrics -metricsPort 3001 -verbose -unsafe-logging 

        ${config.exporter.run}
      '';
    };

    "down.sh" = {
      executable = true;
      text = ''
        podman stop -t 10 snowflake-proxy-1
        podman stop -t 10 snowflake-proxy-2
        podman rm snowflake-proxy-1 snowflake-proxy-2
        ${config.exporter.stop}
        podman pod rm ${config.pod-name}
      '';
    };
  };
}
