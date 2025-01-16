{ lib, config, home, pkgs, clib, mainConfig, inputs, ... }:
let
  MARIA_ROOT_PASS = ''$(cat "${mainConfig.age.secrets.nextcloud_maria_root_pass.path}")'';
  MARIA_PASS = ''$(cat "${mainConfig.age.secrets.nextcloud_maria_pass.path}")'';
  NEXTCLOUD_ADMIN_PASS = ''$(cat "${mainConfig.age.secrets.nextcloud_admin_pass.path}")'';
  MARIA_USER = "nextcloud";
  MARIA_DATABASE = "nextcloud";
  ADMIN_USER = "admin";
in
{
  imports = [
    ../../shared/baseuser.nix
  ];

  home.activation.script = clib.create-folders lib [
    "${config.data-prefix}/nextcloud/"
    "${config.data-prefix}/db/"
  ];

  home.file = clib.create-files config.home.homeDirectory {
    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${config.pod-name} --userns=keep-id \
            -p ${mainConfig.address.public.nextcloud}:8080 \
            -p ${config.exporter.port} \
            --network pasta:-a,172.16.0.1

        podman run --name=nextcloud-db -d --pod=${config.pod-name} \
            -e MYSQL_ROOT_PASSWORD=${MARIA_ROOT_PASS} \
            -e MYSQL_PASSWORD=${MARIA_PASS} \
            -e MYSQL_DATABASE=${MARIA_DATABASE} \
            -e MYSQL_USER=${MARIA_USER} \
            -v ${config.data-prefix}/db:/var/lib/mysql:U \
            --restart on-failure:10 \
            -u $UID:$GID \
            docker.io/mariadb:${mainConfig.image-versions."docker.io/mariadb"} \
            --transaction-isolation=READ-COMMITTED --log-bin=binlog --binlog-format=ROW

        podman run --name=nextcloud -d --pod=${config.pod-name} \
            -e MYSQL_PASSWORD=${MARIA_PASS} \
            -e MYSQL_DATABASE=${MARIA_DATABASE} \
            -e MYSQL_USER=${MARIA_USER} \
            -e MYSQL_HOST=127.0.0.1 \
            -e NEXTCLOUD_ADMIN_USER=${ADMIN_USER} \
            -e NEXTCLOUD_ADMIN_PASSWORD=${NEXTCLOUD_ADMIN_PASS} \
            -e OVERWRITEHOST=${mainConfig.sites.nextcloud}.${mainConfig.main-url} \
            -e TRUSTED_PROXIES=${mainConfig.server."${mainConfig.hostnames.main-1}".private-ip} \
            -e OVERWRITEPROTOCOL=https \
            -v ${config.data-prefix}/nextcloud:/var/www/html:U \
            -v ${config.home.homeDirectory}/apache2/ports.conf:/etc/apache2/ports.conf:ro \
            -v ${config.home.homeDirectory}/apache2/000-default.conf:/etc/apache2/sites-available/000-default.conf:ro \
            --restart on-failure:10 \
            -u $UID:$GID \
            docker.io/nextcloud:${mainConfig.image-versions."docker.io/nextcloud"}

        ${config.exporter.run}
      '';
    };

    "down.sh" = {
      executable = true;
      text = ''
        podman stop -t 10 nextcloud
        podman stop -t 10 nextcloud-db
        podman rm nextcloud nextcloud-db
        ${config.exporter.stop}
        podman pod rm ${config.pod-name}
      '';
    };

    "apache2/ports.conf" = {
      noLink = true;
      text = ''
        Listen 8080
      '';
    };

    "apache2/000-default.conf" = {
      noLink = true;
      text = ''
        <VirtualHost *:8080>
          DocumentRoot /var/www/html

          ErrorLog ''${APACHE_LOG_DIR}/error.log
          CustomLog ''${APACHE_LOG_DIR}/access.log combined
        </VirtualHost>
      '';
    };
  };
}
