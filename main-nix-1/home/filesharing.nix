{ age, clib }: { lib, config, home, pkgs, inputs, ... }:
let
  FILESHARING_VERSION = "v1.5.1";

  ADMIN_PASSWORD = ''$(cat "${age.secrets.filesharing_admin_pass.path}")'';
  ADMIN_EMAIL = ''$(cat "${age.secrets.filesharing_admin_email.path}")'';
  USER_PASSWORD = ''$(cat "${age.secrets.filesharing_user_pass.path}")'';
in
{
  imports = [
    ../../shared/usr.nix
  ];

  home.activation.script = clib.create-folders lib [
    "${config.data-prefix}/pb_data/"
  ];

  home.file = clib.create-files config.home.homeDirectory {
    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${config.pod-name} \
            -p ${config.address.public.filesharing}:80 \
            -p ${exporter.port} \
            --network pasta:-a,172.16.0.1

        podman run --name=filesharing -d --pod=${config.pod-name} \
            -e ADMIN_PASSWORD="${ADMIN_PASSWORD}" \
            -e ADMIN_EMAIL="${ADMIN_EMAIL}" \
            -e USER_PASSWORD="${USER_PASSWORD}" \
            -e APP_NAME="H3rmt File Sharing" \
            -v ${config.data-prefix}/pb_data/:/app/pb_data \
            --restart unless-stopped \
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
