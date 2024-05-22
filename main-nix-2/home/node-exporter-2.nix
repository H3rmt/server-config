{ age, clib, mconfig }: { lib, config, home, pkgs, inputs, ... }:
let
  PODNAME = "node-exporter-2_pod";
  NODE_EXPORTER_VERSION = "v1.7.0";

  exporter = clib.create-podman-exporter "node-exporter-2" "${PODNAME}";
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
            -p ${mconfig.main-nix-2-private-ip}:${toString mconfig.ports.private.node-exporter-2}:9100 \
            -p ${mconfig.main-nix-2-private-ip}:${exporter.port} \
            --network pasta:-a,172.16.0.1

        podman run --name=node-exporter-2 -d --pod=${PODNAME} \
            -v '/:/host:ro,rslave' \
            -u 0:0 \
            --restart unless-stopped \
            docker.io/prom/node-exporter:${NODE_EXPORTER_VERSION} \
            --path.rootfs=/host --collector.processes

        ${exporter.run}
      '';
    };

    "down.sh" = {
      executable = true;
      text = ''
        podman stop -t 10 node-exporter-2
        podman rm node-exporter-2
        ${exporter.stop}
        podman pod rm ${PODNAME}
      '';
    };
  };
}
