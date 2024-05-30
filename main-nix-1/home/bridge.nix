{ age, clib }: { lib, config, home, pkgs, inputs, ... }:
let
  TOR_VERSION = "v0.3.3-exporter";
in
{
  imports = [
    ../../shared/usr.nix
  ];

  home.activation.script = clib.create-folders lib [
    "${config.data-prefix}/bridge/"
  ];

  home.file = clib.create-files config.home.homeDirectory {
    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${config.pod-name} --userns=keep-id \
            -p ${toString config.ports.exposed.tor-bridge}:9100 \
            -p ${toString config.ports.exposed.tor-bridge-pt}:9140 \
            -p ${config.address.private.tor-exporter}:9099 \
            -p ${config.exporter.port} \
            --network pasta:-a,172.16.0.1

        podman run --name=bridge -d --pod=${config.pod-name} \
            -v logs:/var/log/tor:U \
            -e mode="bridge" \
            -e Nickname="Bridge" \
            -e ContactInfo="${config.email}" \
            -e ORPort=9100 \
            -e PTPort=9140 \
            -e AccountingStart="week 1 00:00" \
            -e AccountingMax="4 TBytes" \
            -e RelayBandwidthRate="1.5 MBytes" \
            -e RelayBandwidthBurst="2.5 MBytes" \
            -e MetricsPort=9035 \
            -e ControlPort=9051 \
            -v ${config.data-prefix}/bridge:/var/lib/tor:U \
            -v config:/etc/tor:U \
            --restart on-failure:10 \
            ghcr.io/h3rmt/alpine-tor:${TOR_VERSION}

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
