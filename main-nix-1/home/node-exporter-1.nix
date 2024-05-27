{ age, clib, mconfig }: { lib, config, home, pkgs, inputs, ... }:
let
  PODNAME = "node-exporter-1_pod";
  NODE_EXPORTER_VERSION = "v1.7.0";

  exporter = clib.create-podman-exporter "node-exporter-1" "${PODNAME}";
in
{
  imports = [
    ../../shared/usr.nix
  ];
  home.stateVersion = mconfig.nixVersion;
  home.sessionVariables.XDG_RUNTIME_DIR = "/run/user/$UID";

  home.file = clib.create-files config.home.homeDirectory {
    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${PODNAME} \
            -p ${mconfig.main-nix-1-private-ip}:${toString mconfig.ports.private.node-exporter-1}:9100 \
            -p ${mconfig.main-nix-1-private-ip}:${exporter.port} \
            --network pasta:-a,172.16.0.1

        podman run --name=node-exporter-1 -d --pod=${PODNAME} \
            -v '/:/host:ro,rslave' \
            -u 0:0 \
            --restart unless-stopped \
            docker.io/prom/node-exporter:${NODE_EXPORTER_VERSION} \
            --path.rootfs=/host --collector.netdev --collector.processes --collector.ethtool

        ${exporter.run}
      '';
    };

    "down.sh" = {
      executable = true;
      text = ''
        podman stop -t 10 node-exporter-1
        podman rm node-exporter-1
        ${exporter.stop}
        podman pod rm ${PODNAME}
      '';
    };
  };
}
