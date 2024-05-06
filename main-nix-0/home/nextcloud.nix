{ age, clib }: { lib, config, home, pkgs, inputs, ... }:
let
  volume-prefix = "${config.volume}/Nextcloud";

  PODNAME = "nextcloud_pod";
  MARIA_VERSION = "10.6";
  NEXTCLOUD_VERSION = "28.0.4";

  MARIA_ROOT_PASS = ''$(cat "${age.secrets.nextcloud_maria_root_pass.path}")'';
  MARIA_PASS = ''$(cat "${age.secrets.nextcloud_maria_pass.path}")'';
  MARIA_USER = "nextcloud";
  MARIA_DATABASE = "nextcloud";

  exporter = clib.create-podman-exporter "nextcloud" "${PODNAME}";
in
{
  imports = [
    ../vars.nix
    ../zsh.nix
  ];
  home.stateVersion = config.nixVersion;
  home.sessionVariables.XDG_RUNTIME_DIR = "/run/user/$UID";

  home.file = clib.create-files config.home.homeDirectory {
    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${PODNAME} \
            -p ${toString config.ports.public.nextcloud}:80 \
            -p ${exporter.port} \
            --network pasta:-a,10.0.0.1
            
        podman run --name=nextcloud -d --pod=${PODNAME} \
            -e MYSQL_ROOT_PASSWORD=${MARIA_ROOT_PASS} \
            -e MYSQL_PASSWORD=${MARIA_PASS} \
            -e MYSQL_DATABASE=${MARIA_DATABASE} \
            -e MYSQL_USER=${MARIA_USER} \
            -e OVERWRITEHOST=${config.sites.nextcloud}.${config.main-url} \
            -e OVERWRITEPROTOCOL=https \
            -v ${volume-prefix}/data2:/var/www/html \
            docker.io/nextcloud:${NEXTCLOUD_VERSION}

        podman run --name=nextcloud-db -d --pod=${PODNAME} \
            -e MYSQL_ROOT_PASSWORD=${MARIA_ROOT_PASS} \
            -e MYSQL_PASSWORD=${MARIA_PASS} \
            -e MYSQL_DATABASE=${MARIA_DATABASE} \
            -e MYSQL_USER=${MARIA_USER} \
            -v ${volume-prefix}/db2:/var/lib/mysql \
            docker.io/mariadb:${MARIA_VERSION} \
            --transaction-isolation=READ-COMMITTED --log-bin=binlog --binlog-format=ROW
        
        ${exporter.run}    
      '';
    };

    "down.sh" = {
      executable = true;
      text = ''
        podman stop -t 10 nextcloud
        podman stop -t 10 nextcloud-db
        podman rm nextcloud nextcloud-db
        ${exporter.stop}
        podman pod rm ${PODNAME}
      '';
    };
  };
}
