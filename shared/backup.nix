{ lib, config, pkgs, ... }:
let
  BORGMATIC_VERSION = "1.9.1";
  generatedServices = (map
    (user: {
      "borgmatic_${user}" = {
        description = "Service for Borgmatic ${user} user";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellApplication
            {
              name = "borgmatic_${user}";
              runtimeInputs = [ pkgs.coreutils pkgs.podman ];
              text = ''
                start_time=$(date +%s)

                mkdir -p /var/backups/${user}/config /var/backups/${user}/cache
                mkdir -p /home/${config.backup-user-prefix}-${config.networking.hostName}/${config.data-dir}/${config.networking.hostName}/${user}

                # create /etc/borgmatic.d/config.yaml
                cat >/var/backups/${user}/config.yaml <<EOF
                source_directories:
                  - /mnt/source
                repositories:
                  - path: /mnt/borg-repository
                    label: mount
                compression: zstd,12
                keep_within: 3H
                keep_daily: 7
                keep_weekly: 4
                keep_monthly: 6
                keep_yearly: 1
                EOF

                cat >/var/backups/${user}/borgmatic.sh <<EOF
                borgmatic config validate --verbosity 1

                if [ -z "\$(ls -A /mnt/borg-repository)" ]; then
                  echo "Starting Initial Borgmatic backup"
                  borgmatic init --encryption repokey-blake2 --verbosity 1
                  borgmatic create --list --stats --verbosity 1
                fi

                echo "Starting Borgmatic backup"
                borgmatic create --stats --list --verbosity 1 --syslog-verbosity 0

                echo "Starting Borgmatic prune"
                borg prune --keep-daily 7 --keep-monthly 6 --keep-weekly 4 --keep-yearly 1 --glob-archives {hostname}-* --stats --list --debug --show-rc /mnt/borg-repository

                echo "Starting Borgmatic compact"
                borg compact --debug --show-rc /mnt/borg-repository

                echo "Starting Borgmatic check"
                borgmatic check --verbosity 1
                EOF

                podman pull ghcr.io/borgmatic-collective/borgmatic:${BORGMATIC_VERSION}
                podman run --rm --name borgmatic-${user} \
                  -e BORG_PASSPHRASE="$(cat ${config.age.secrets.borg_pass.path})" \
                  -v /home/${user}/${config.data-dir}:/mnt/source:ro \
                  -v /home/${config.backup-user-prefix}-${config.networking.hostName}/${config.data-dir}/${config.networking.hostName}/${user}:/mnt/borg-repository \
                  -v /var/backups/${user}/config:/root/.config/borg \
                  -v /var/backups/${user}/cache:/root/.cache/borg \
                  -v /var/backups/${user}/borgmatic.sh:/root/borgmatic.sh \
                  -v /var/backups/${user}/config.yaml:/etc/borgmatic.d/config.yaml \
                  -e TZ=Europe/Berlin \
                  --entrypoint bash \
                  ghcr.io/borgmatic-collective/borgmatic:${BORGMATIC_VERSION} \
                  -c "/root/borgmatic.sh"

                echo "Borgmatic backup for ${user} finished in $(($(date +%s) - start_time)) seconds"

                # Wait for at least 25 seconds before exiting
                while [ $(($(date +%s) - start_time)) -lt 25 ]; do
                  sleep 1  # Sleep for a short duration before checking again
                done
              '';
            } + "/bin/borgmatic_${user}";
          Restart = "on-failure";
          RestartSec = "30";
        };
      };
    })
    config.server."${config.networking.hostName}".backup-users);

  backup = {
    description = "Rscync backups with ssh to other users";
    requires = lib.forEach config.server."${config.networking.hostName}".backup-users (name: "borgmatic_${name}.service");
    after = lib.forEach config.server."${config.networking.hostName}".backup-users (name: "borgmatic_${name}.service");
    serviceConfig = {
      Type = "exec";
      ExecStart = pkgs.writeShellApplication
        {
          name = "Rsync";
          runtimeInputs = [ pkgs.rsync pkgs.openssh ];
          text = ''
            start_time=$(date +%s)

            ${lib.concatMapStringsSep "  " (remote: ''
              rsync -aP --mkpath --delete -e "ssh -i /etc/ssh/ssh_host_ed25519_key -o StrictHostKeyChecking=no" /home/${config.backup-user-prefix}-${config.networking.hostName}/${config.data-dir}/${config.networking.hostName}/ ${config.backup-user-prefix}-${remote}@${config.server."${remote}"."private-ip"}:/home/${config.backup-user-prefix}-${remote}/${config.data-dir}/${config.networking.hostName}
            '') (lib.filter (r: r != config.networking.hostName) (lib.attrValues config.hostnames))}

            echo "Rsync backup finished in $(($(date +%s) - start_time)) seconds"

            # Wait for at least 25 seconds before exiting
            while [ $(($(date +%s) - start_time)) -lt 25 ]; do
              sleep 1  # Sleep for a short duration before checking again
            done
          '';
        } + "/bin/Rsync";
      Restart = "on-failure";
      RestartSec = "30";
    };
  };

  exporter = {
    description = "Service for Systemd Exporter: ${builtins.toJSON (lib.forEach config.server."${config.networking.hostName}".backup-users (name: "borgmatic_${name}.service"))} and backup.service";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = ''
        ${pkgs.prometheus-systemd-exporter}/bin/systemd_exporter \
          --web.listen-address ${config.address.private.systemd-exporter."${config.networking.hostName}"} --systemd.collector.unit-include="${lib.concatStringsSep "|" (lib.forEach config.server."${config.networking.hostName}".backup-users (name: "borgmatic_${name}.service"))}|backup.service|backup.timer"
      '';
    };
  };
in
{
  systemd.services = { inherit backup; inherit exporter; } // (lib.foldl' (acc: service: acc // service) { } generatedServices); # merge all generated services

  systemd.timers."backup" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      Unit = "backup.service";
      OnBootSec = "120";
      OnCalendar = "*:${toString config.server."${config.networking.hostName}".backup-trigger-minutes}";
      Persistent = true;
    };
  };
}
