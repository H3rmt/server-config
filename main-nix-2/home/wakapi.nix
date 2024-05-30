{ age, clib }: { lib, config, home, pkgs, inputs, ... }:
let
  WAKAPI_VERSION = "2.11.2";
in
{
  imports = [
    ../../shared/usr.nix
  ];

  home.activation.script = clib.create-folders lib [
    "${config.data-prefix}/wakapi/"
  ];

  home.file = clib.create-files config.home.homeDirectory {
    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${config.pod-name} --userns=keep-id \
            -p ${config.address.public.wakapi}:3000 \
            -p ${config.exporter.port} \
            --network pasta:-a,172.16.0.1
        
        podman run --name=wakapi -d --pod=${config.pod-name} \
            -e WAKAPI_INACTIVE_DAYS=14 \
            -e WAKAPI_SUPPORT_CONTACT="${config.email}" \
            -e WAKAPI_MAX_INACTIVE_MONTHS=-1 \
            -e WAKAPI_PUBLIC_URL="https://${config.sites.wakapi}.${config.main-url}/" \
            -e WAKAPI_DISABLE_FRONTPAGE=false \
            -e WAKAPI_EXPOSE_METRICS=true \
            -e WAKAPI_TRUSTED_HEADER_AUTH=true \
            -e WAKAPI_TRUST_REVERSE_PROXY_IPS=${config.main-nix-2-private-ip} \
            -e WAKAPI_MAIL_ENABLED=false \
            -v ${config.data-prefix}/wakapi:/data:U \
            --restart on-failure:10 \
            -u $UID:$GID \
            ghcr.io/muety/wakapi:${WAKAPI_VERSION} 

        ${config.exporter.run}
      '';
    };

    "down.sh" = {
      executable = true;
      text = ''
        podman stop -t 10 wakapi
        podman rm wakapi
        ${config.exporter.stop}
        podman pod rm ${config.pod-name}
      '';
    };
  };
}
