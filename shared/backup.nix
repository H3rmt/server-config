{ lib, config, pkgs, ... }:
let
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
                location:
                  source_directories:
                    - /mnt/source
                  repositories:
                    - /mnt/borg-repository
                  encryption_passcommand: "cat ${config.age.secrets.borg_pass.path}"
                  compression: zstd,12
                  keep_daily: 7
                  keep_weekly: 4
                  keep_monthly: 6
                  keep_yearly: 1
                EOF

                cat >/var/backups/${user}/borgmatic.sh <<EOF
                borgmatic config validate --verbosity 1

                if [ -z "$(ls -A /mnt/borg-repository)" ]; then
                  echo "Starting Initial Borgmatic backup"
                  borgmatic init --encryption repokey-blake2 --verbosity 1
                  borgmatic create --list --stats --verbosity 1
                fi

                borgmatic --stats --list --verbosity 1 --syslog-verbosity 0
                EOF

                podman pull ghcr.io/borgmatic-collective/borgmatic:1.9.1
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
                  ghcr.io/borgmatic-collective/borgmatic:1.9.1 \
                  -c "ls -la /root && cat /root/borgmatic.sh && chmod +x /root/borgmatic.sh && /root/borgmatic.sh"

                echo "Borgmatic backup for ${user} finished in $(($(date +%s) - start_time)) seconds"

                # Wait for at least 15 seconds before exiting
                while [ $(($(date +%s) - start_time)) -lt 15 ]; do
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
              rsync -aP --mkpath --delete -e "ssh -i /etc/ssh/ssh_host_ed25519_key -o StrictHostKeyChecking=no" /home/${config.backup-user-prefix}-${config.networking.hostName}/${config.data-dir}/${config.networking.hostName} ${config.backup-user-prefix}-${remote}@${config.server."${remote}"."private-ip"}:/home/${config.backup-user-prefix}-${remote}/${config.data-dir}/${config.networking.hostName}
            '') (lib.filter (r: r != config.networking.hostName) (lib.attrValues config.hostnames))}

            echo "Rsync backup finished in $(($(date +%s) - start_time)) seconds"

            # Wait for at least 15 seconds before exiting
            while [ $(($(date +%s) - start_time)) -lt 15 ]; do
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
