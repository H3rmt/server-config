{ age, clib }: { lib, config, home, pkgs, inputs, ... }:
let
  TOR_VERSION = "v0.3.2-exporter";
in
{
  imports = [
    ../../shared/usr.nix
  ];

  home.activation.script = clib.create-folders lib [
    "${config.data-prefix}/middle/"
  ];

  home.file = clib.create-files config.home.homeDirectory {
    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${config.pod-name} \
            -p ${toString config.ports.exposed.tor-middle}:9000 \
            -p ${toString config.ports.exposed.tor-middle-dir}:9030 \
            -p ${config.address.private.tor-exporter}:9099 \
            -p ${config.exporter.port} \
            --network pasta:-a,172.16.0.1

        podman run --name=middle -d --pod=${config.pod-name} \
            -e mode="middle" \
            -e Nickname="Middle" \
            -e ContactInfo="${config.email}" \
            -e ORPort=9000 \
            -e DirPort=9030 \
            -e AccountingStart="week 1 00:00" \
            -e AccountingMax="4 TBytes" \
            -e RelayBandwidthRate="1.2 MBytes" \
            -e RelayBandwidthBurst="2.5 MBytes" \
            -e MetricsPort=9035 \
            -e ControlPort=9051 \
            -v ${config.data-prefix}/middle:/var/lib/tor \
            -u 0:0 \
            --restart unless-stopped \
            ghcr.io/h3rmt/alpine-tor:${TOR_VERSION}

        ${config.exporter.run}
      '';
    };

    "down.sh" = {
      executable = true;
      text = ''
        podman stop -t 10 middle 
        podman rm middle
        ${config.exporter.stop}
        podman pod rm ${config.pod-name}
      '';
    };
  };
}
