{ lib, config, clib, mainConfig, ... }: 
let
  BORG_EXPORTER_VERSION = "v0.0.2";
in
{
  imports = [
    ../baseuser.nix
  ];

  home.file = clib.create-files config.home.homeDirectory {
    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${config.pod-name} --userns=keep-id \
            -p ${mainConfig.address.private.borg-exporter."${mainConfig.backup-user-prefix}-${mainConfig.networking.hostName}"}:5000 \
            -p ${config.exporter.port} \
            --network pasta:-a,172.16.0.1

        podman run --name=borg-exporter-${mainConfig.networking.hostName} -d --pod=${config.pod-name} \
            -v ${config.data-prefix}/:/mnt:ro' \
            -e REPO_CONFIG="\
              ${lib.concatStringsSep "," (lib.forEach mainConfig.server.${mainConfig.hostnames.main-1}.backup-users (repo: "/mnt/${mainConfig.hostnames.main-1}/${repo}=$(cat ${mainConfig.age.secrets."borg_pass_${mainConfig.hostnames.main-1}".path})"))},\
              ${lib.concatStringsSep "," (lib.forEach mainConfig.server.${mainConfig.hostnames.main-2}.backup-users (repo: "/mnt/${mainConfig.hostnames.main-2}/${repo}=$(cat ${mainConfig.age.secrets."borg_pass_${mainConfig.hostnames.main-2}".path})"))},\
              ${lib.concatStringsSep "," (lib.forEach mainConfig.server.${mainConfig.hostnames.raspi-1}.backup-users(repo: "/mnt/${mainConfig.hostnames.raspi-1}/${repo}=$(cat ${mainConfig.age.secrets."borg_pass_${mainConfig.hostnames.raspi-1}".path})"))}" \
            --restart on-failure:10 \
            -u $UID:$GID \
            ghcr.io/h3rmt/borg-prometheus-exporter:${BORG_EXPORTER_VERSION} \
            -p 5000 -b 0.0.0.0

        ${config.exporter.run}
      '';
    };

    "down.sh" = {
      executable = true;
      text = ''
        podman stop -t 10 node-exporter-${mainConfig.networking.hostName}
        podman rm borg-exporter-${mainConfig.networking.hostName}
        ${config.exporter.stop}
        podman pod rm ${config.pod-name}
      '';
    };
  };
}
