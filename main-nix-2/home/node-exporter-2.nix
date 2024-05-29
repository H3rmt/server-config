{ age, clib }: { lib, config, home, pkgs, inputs, ... }:
let
  NODE_EXPORTER_VERSION = "v1.7.0";
in
{
  imports = [
    ../../shared/usr.nix
  ];

  home.file = clib.create-files config.home.homeDirectory {
    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${config.pod-name} \
            -p ${config.address.private.node-exporter-2}:9100 \
            -p ${config.exporter.port} \
            --network pasta:-a,172.16.0.1

        podman run --name=node-exporter-2 -d --pod=${config.pod-name} \
            -v '/:/host:ro,rslave' \
            -u 0:0 \
            --restart unless-stopped \
            docker.io/prom/node-exporter:${NODE_EXPORTER_VERSION} \
            --path.rootfs=/host --collector.netdev --collector.processes --collector.ethtool

        ${config.exporter.run}
      '';
    };

    "down.sh" = {
      executable = true;
      text = ''
        podman stop -t 10 node-exporter-2
        podman rm node-exporter-2
        ${config.exporter.stop}
        podman pod rm ${config.pod-name}
      '';
    };
  };
}
