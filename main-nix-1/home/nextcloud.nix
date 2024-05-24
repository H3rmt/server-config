{ age, clib, mconfig }: { lib, config, home, pkgs, inputs, ... }:
let
  data-prefix = "${config.home.homeDirectory}/data";

  PODNAME = "nextcloud_pod";
  MARIADB_VERSION = "11.0.0";
  NEXTCLOUD_VERSION = "29.0.0";

  MARIA_ROOT_PASS = ''$(cat "${age.secrets.nextcloud_maria_root_pass.path}")'';
  MARIA_PASS = ''$(cat "${age.secrets.nextcloud_maria_pass.path}")'';
  NEXTCLOUD_ADMIN_PASS = ''$(cat "${age.secrets.nextcloud_admin_pass.path}")'';
  MARIA_USER = "nextcloud";
  ADMIN_USER = "admin";
  MARIA_DATABASE = "nextcloud";

  exporter = clib.create-podman-exporter "nextcloud" "${PODNAME}";
in
{
  imports = [
    ../../shared/usr.nix
  ];
  home.stateVersion = mconfig.nixVersion;
  home.sessionVariables.XDG_RUNTIME_DIR = "/run/user/$UID";

  home.activation.script = clib.create-folders lib [
    "${data-prefix}/nextcloud/"
    "${data-prefix}/db/"
  ];

  home.file = clib.create-files config.home.homeDirectory {
    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${PODNAME} \
            -p ${mconfig.main-nix-1-private-ip}:${toString mconfig.ports.public.nextcloud}:80 \
            -p ${mconfig.main-nix-1-private-ip}:${exporter.port} \
            --network pasta:-a,172.16.0.1

        podman run --name=nextcloud-db -d --pod=${PODNAME} \
            -e MYSQL_ROOT_PASSWORD=${MARIA_ROOT_PASS} \
            -e MYSQL_PASSWORD=${MARIA_PASS} \
            -e MYSQL_DATABASE=${MARIA_DATABASE} \
            -e MYSQL_USER=${MARIA_USER} \
            -v ${data-prefix}/db:/var/lib/mysql \
            docker.io/mariadb:${MARIADB_VERSION} \
            --transaction-isolation=READ-COMMITTED --log-bin=binlog --binlog-format=ROW

        podman run --name=nextcloud -d --pod=${PODNAME} \
            -e MYSQL_PASSWORD=${MARIA_PASS} \
            -e MYSQL_DATABASE=${MARIA_DATABASE} \
            -e MYSQL_USER=${MARIA_USER} \
            -e MYSQL_HOST=localhost \
            -e NEXTCLOUD_ADMIN_USER=${ADMIN_USER} \
            -e NEXTCLOUD_ADMIN_PASSWORD=${NEXTCLOUD_ADMIN_PASS} \
            -e OVERWRITEHOST=${mconfig.sites.nextcloud}.${mconfig.main-url} \
            -e TRUSTED_PROXIES=${mconfig.main-nix-2-private-ip} \
            -e OVERWRITEPROTOCOL=https \
            -v ${data-prefix}/nextcloud:/var/www/html \
            docker.io/nextcloud:${NEXTCLOUD_VERSION}

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
