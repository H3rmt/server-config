{ age, clib, mconfig }: { lib, config, home, pkgs, inputs, ... }:
let
  data-prefix = "${config.home.homeDirectory}/${mconfig.data-dir}";

  PODNAME = "tor_pod";
  TOR_VERSION = "v0.2.6";
  TOR_EXPORTER_VERSION = "v0.2.1";

  exporter = clib.create-podman-exporter "tor" "${PODNAME}";
in
{
  imports = [
    ../../shared/usr.nix
  ];
  home.stateVersion = mconfig.nixVersion;
  home.sessionVariables.XDG_RUNTIME_DIR = "/run/user/$UID";

  home.activation.script = clib.create-folders lib [
    "${data-prefix}/middle/"
  ];

  home.file = clib.create-files config.home.homeDirectory {
    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${PODNAME} \
            -p ${toString mconfig.ports.exposed.tor-middle}:9000 \
            -p ${mconfig.main-nix-2-private-ip}:${toString mconfig.ports.private.tor-exporter}:9099 \
            -p ${mconfig.main-nix-2-private-ip}:${exporter.port} \
            --network pasta:-a,172.16.0.1

        podman run --name=middle -d --pod=${PODNAME} \
            -e mode="middle" \
            -e Nickname="Middle" \
            -e ContactInfo="stemmer.enrico@gmail.com" \
            -e ORPort=9000 \
            -e AccountingStart="week 1 00:00" \
            -e AccountingMax="4 TBytes" \
            -e RelayBandwidthRate="1 MBytes" \
            -e RelayBandwidthBurst="2 MBytes" \
            -e MetricsPort=9035 \
            -e ControlPort=9051 \
            -e MetricsPortPolicy="accept 127.0.0.1" \
            -v ${data-prefix}/middle:/var/lib/tor \
            -v /proc \
            -u 0:0 \
            --restart unless-stopped \
            docker.io/h3rmt/alpine-tor:${TOR_VERSION}

        podman run --name=middle-exporter -d --pod=${PODNAME} \
            --volumes-from=middle \
            --restart unless-stopped \
            ghcr.io/h3rmt/tor-exporter:${TOR_EXPORTER_VERSION} \
            -m=tcp -a=127.0.0.1 -c=9051 -b=0.0.0.0 -p=9099

        ${exporter.run}
      '';
    };

    "down.sh" = {
      executable = true;
      text = ''
        podman stop -t 10 middle-exporter
        podman stop -t 10 middle 
        podman rm middle middle-exporter
        ${exporter.stop}
        podman pod rm ${PODNAME}
      '';
    };
  };
}
