{ age, clib, mconfig }: { lib, config, home, pkgs, inputs, ... }:
let
  volume-prefix = "${config.home.homeDirectory}/data";

  PODNAME = "filesharing_pod";
  FILESHARING_VERSION = "v1.5.1";

  ADMIN_PASSWORD = ''$(cat "${age.secrets.filesharing_admin_pass.path}")'';
  ADMIN_EMAIL = ''$(cat "${age.secrets.filesharing_admin_email.path}")'';
  USER_PASSWORD = ''$(cat "${age.secrets.filesharing_user_pass.path}")'';

  exporter = clib.create-podman-exporter "filesharing" "${PODNAME}";
in
{
  imports = [
    ../../zsh.nix
  ];
  home.stateVersion = mconfig.nixVersion;
  home.sessionVariables.XDG_RUNTIME_DIR = "/run/user/$UID";

  home.file = clib.create-files config.home.homeDirectory {
    "${volume-prefix}/pb_data/.keep" = {
      text = "";
    };

    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${PODNAME} \
            -p ${toString mconfig.ports.public.filesharing}:3000 \
            -p ${exporter.port} \
            --network pasta:-a,10.0.0.1

        podman run --name=filesharing -d --pod=${PODNAME} \
            -e ADMIN_PASSWORD="${ADMIN_PASSWORD}" \
            -e ADMIN_EMAIL="${ADMIN_EMAIL}" \
            -e USER_PASSWORD="${USER_PASSWORD}" \
            -e APP_NAME="H3rmt File Sharing" \
            -v ${volume-prefix}/pb_data/:/app/pb_data \
            --restart unless-stopped \
            docker.io/h3rmt/filesharing:${FILESHARING_VERSION}

        ${exporter.run}
      '';
    };

    "down.sh" = {
      executable = true;
      text = ''
        podman stop -t 10 filesharing
        podman rm filesharing
        ${exporter.stop}
        podman pod rm ${PODNAME}
      '';
    };
  };
}
