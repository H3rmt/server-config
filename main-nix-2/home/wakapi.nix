{ lib, config, home, pkgs, clib, mainConfig, inputs, ... }:
let
  WAKAPI_VERSION = "2.11.2";

  SALT = ''$(cat "${mainConfig.age.secrets.wakapi_salt.path}")'';
in
{
  imports = [
    ../../shared/baseuser.nix
  ];

  home.activation.script = clib.create-folders lib [
    "${config.data-prefix}/wakapi/"
  ];

  home.file = clib.create-files config.home.homeDirectory {
    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${config.pod-name} --userns=keep-id \
            -p ${mainConfig.address.public.wakapi}:3000 \
            -p ${config.exporter.port} \
            --network pasta:-a,172.16.0.1
        
        podman run --name=wakapi -d --pod=${config.pod-name} \
            -e WAKAPI_INACTIVE_DAYS=14 \
            -e WAKAPI_SUPPORT_CONTACT="${mainConfig.email}" \
            -e WAKAPI_MAX_INACTIVE_MONTHS=-1 \
            -e WAKAPI_PUBLIC_URL="https://${mainConfig.sites.wakapi}.${mainConfig.main-url}/" \
            -e WAKAPI_DISABLE_FRONTPAGE=true \
            -e WAKAPI_EXPOSE_METRICS=true \
            -e WAKAPI_TRUSTED_HEADER_AUTH=true \
            -e WAKAPI_TRUSTED_HEADER_AUTH_KEY="X-wakapi-username" \
            -e WAKAPI_TRUST_REVERSE_PROXY_IPS=${mainConfig.server."${mainConfig.hostnames.main-2}".private-ip} \
            -e WAKAPI_MAIL_ENABLED=false \
            -e WAKAPI_PASSWORD_SALT=${SALT} \
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
