{ lib, config, home, pkgs, clib, mainConfig, inputs, ... }:
let
in
{
  imports = [
    ../../shared/baseuser.nix
  ];

  home.file = clib.create-files config.home.homeDirectory {
    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${config.pod-name} --userns=keep-id \
            -p ${mainConfig.address.private.snowflake-exporter-1}:3000 \
            -p ${mainConfig.address.private.snowflake-exporter-2}:3001 \
            -p ${config.exporter.port} \
            --network pasta:-a,172.16.0.1

        podman run --name=snowflake-proxy-1 -d --pod=${config.pod-name} \
            --restart on-failure:10 \
            -u $UID:$GID \
            docker.io/thetorproject/snowflake-proxy:${mainConfig.image-versions."docker.io/thetorproject/snowflake-proxy"} \
            -metrics -metrics-port 3000 -unsafe-logging -summary-interval 12h

        podman run --name=snowflake-proxy-2 -d --pod=${config.pod-name} \
            --restart on-failure:10 \
            -u $UID:$GID \
            docker.io/thetorproject/snowflake-proxy:${mainConfig.image-versions."docker.io/thetorproject/snowflake-proxy"} \
            -metrics -metrics-port 3001 -unsafe-logging -summary-interval 12h

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
