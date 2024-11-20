{ lib, config, home, pkgs, clib, mainConfig, inputs, ... }:
let
  FILESHARING_VERSION = "v1.6.0";

  ADMIN_PASSWORD = ''$(cat "${mainConfig.age.secrets.filesharing_admin_pass.path}")'';
  ADMIN_EMAIL = ''$(cat "${mainConfig.age.secrets.filesharing_admin_email.path}")'';
  USER_PASSWORD = ''$(cat "${mainConfig.age.secrets.filesharing_user_pass.path}")'';
in
{
  imports = [
    ../../shared/baseuser.nix
  ];

  home.activation.script = clib.create-folders lib [
    "${config.data-prefix}/pb_data/"
  ];

  home.file = clib.create-files config.home.homeDirectory {
    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${config.pod-name} --userns=keep-id \
            -p ${mainConfig.address.public.filesharing}:8080 \
            -p ${config.exporter.port} \
            --network pasta:-a,172.16.0.1

        podman run --name=filesharing -d --pod=${config.pod-name} \
            -e PORT=8080 \
            -e ADMIN_PASSWORD="${ADMIN_PASSWORD}" \
            -e ADMIN_EMAIL="${ADMIN_EMAIL}" \
            -e USER_PASSWORD="${USER_PASSWORD}" \
            -e APP_NAME="H3rmt File Sharing" \
            -v ${config.data-prefix}/pb_data/:/app/pb_data:U \
            --restart on-failure:10 \
            -u $UID:$GID \
            docker.io/h3rmt/filesharing:${FILESHARING_VERSION}

        ${config.exporter.run}
      '';
    };

    "down.sh" = {
      executable = true;
      text = ''
        podman stop -t 10 filesharing
        podman rm filesharing
        ${config.exporter.stop}
        podman pod rm ${config.pod-name}
      '';
    };
  };
}
