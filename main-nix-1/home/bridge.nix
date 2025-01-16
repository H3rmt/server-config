{ lib, config, home, pkgs, clib, mainConfig, inputs, ... }:
let
in
{
  imports = [
    ../../shared/baseuser.nix
  ];

  home.activation.script = clib.create-folders lib [
    "${config.data-prefix}/bridge/"
  ];

  home.file = clib.create-files config.home.homeDirectory {
    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${config.pod-name} --userns=keep-id \
            -p ${toString mainConfig.ports.exposed.tor-bridge}:9100 \
            -p ${toString mainConfig.ports.exposed.tor-bridge-pt}:9140 \
            -p ${mainConfig.address.private.tor-exporter-bridge}:9099 \
            -p ${config.exporter.port} \
            --network pasta:-a,172.16.0.1

        podman run --name=bridge -d --pod=${config.pod-name} \
            -e mode="bridge" \
            -e Nickname="Bridge" \
            -e ContactInfo="${mainConfig.email}" \
            -e ORPort=9100 \
            -e PTPort=9140 \
            -e AccountingStart="week 1 00:00" \
            -e AccountingMax="4 TBytes" \
            -e RelayBandwidthRate="5.5 MBytes" \
            -e RelayBandwidthBurst="5.5 MBytes" \
            -e MetricsPort=9035 \
            -e ControlPort=9051 \
            -v ${config.data-prefix}/bridge:/var/lib/tor:U \
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
        podman stop -t 10 bridge 
        podman rm bridge
        ${config.exporter.stop}
        podman pod rm ${config.pod-name}
      '';
    };
  };
}
