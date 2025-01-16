{ lib, config, home, pkgs, clib, mainConfig, inputs, ... }:
let
in
{
  imports = [
    ../../shared/baseuser.nix
  ];

  home.activation.script = clib.create-folders lib [
    "${config.data-prefix}/middle/"
  ];

  home.file = clib.create-files config.home.homeDirectory {
    "compare.sh" = {
      executable = true;
      text = ''
        ${config.compare.start}
        echo ghcr.io/h3rmt/alpine-tor:${mainConfig.image-versions."ghcr.io/h3rmt/alpine-tor"}
        ${config.compare.end}
      '';
    };

    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${config.pod-name} --userns=keep-id \
            -p ${toString mainConfig.ports.exposed.tor-middle}:9000 \
            -p ${toString mainConfig.ports.exposed.tor-middle-dir}:9030 \
            -p ${mainConfig.address.private.tor-exporter}:9099 \
            -p ${config.exporter.port} \
            --network pasta:-a,172.16.0.1

        podman run --name=middle -d --pod=${config.pod-name} \
            -e mode="middle" \
            -e Nickname="Middle" \
            -e ContactInfo="${mainConfig.email}" \
            -e ORPort=9000 \
            -e DirPort=9030 \
            -e AccountingStart="week 1 00:00" \
            -e AccountingMax="4 TBytes" \
            -e RelayBandwidthRate="7.0 MBytes" \
            -e RelayBandwidthBurst="7.5 MBytes" \
            -e MetricsPort=9035 \
            -e ControlPort=9051 \
            -v ${config.data-prefix}/middle:/var/lib/tor:U \
            -v config:/etc/tor:U \
            -v logs:/var/log/tor:U \
            --restart on-failure:10 \
            -u $UID:$GID \
            ghcr.io/h3rmt/alpine-tor:${mainConfig.image-versions."ghcr.io/h3rmt/alpine-tor"}

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
