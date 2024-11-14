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
              name = "borgmatic";
              runtimeInputs = [ pkgs.coreutils pkgs.borgmatic ];
              text = ''
                start_time=$(date +%s)

                script+=$(cat <<EOF
                #!/bin/sh

                // create /etc/borgmatic.d/config.yaml
                cat <<EOFF > /etc/borgmatic.d/config.yaml
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
                EOFF
                )

                borgmatic config validate --verbosity 1
                EOF
                )

                if [ -z "$(ls -A /home/${config.backup-user-prefix}-${config.networking.hostName}/${config.data-dir}/${config.networking.hostName}/${user})" ]; then
                  script+=$(cat <<EOF

                  echo "Starting Initial Borgmatic backup"
                  borgmatic init --encryption repokey-blake2 --verbosity 1
                  borgmatic create --list --stats --verbosity 1
                  EOF
                  )
                fi

                script+=$(cat <<EOF

                borgmatic --stats --list --verbosity 1 --syslog-verbosity 0
                EOF
                )

                mkdir -p /var/backups/${user}/config /var/backups/${user}/cache
                mkdir -p /home/${config.backup-user-prefix}-${config.networking.hostName}/${config.data-dir}/${config.networking.hostName}/${user}

                podman pull ghcr.io/borgmatic-collective/borgmatic:1.9.1
                podman run --rm --name borgmatic-${user} \ 
                  -e BORG_PASSPHRASE=$(cat ${config.age.secrets.borg_pass.path}) \
                  -v /home/${user}/${config.backup-dir}:/mnt/source:ro \
                  -v /home/${config.backup-user-prefix}-${config.networking.hostName}/${config.data-dir}/${config.networking.hostName}/${user}:/mnt/borg-repository \
                  -v /var/backups/${user}/config:/root/.config/borg:U \
                  -v /var/backups/${user}/cache:/root/.cache/borg:U \
                  -e TZ=Europe/Berlin \
                  --entrypoint sh \
                  ghcr.io/borgmatic-collective/borgmatic:1.9.1 \
                  -c '"$script"'

                # Wait for at least 30 seconds before exiting
                while [ $(($(date +%s) - start_time)) -lt 30 ]; do
                    sleep 5  # Sleep for a short duration before checking again
                done
              '';
            } + "/bin/borgmatic";
          Restart="on-failure";
          RestartSec="30";
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
          name = "sync";
          runtimeInputs = [ pkgs.rsync pkgs.openssh ];
          text = ''
            start_time=$(date +%s)
            for user in ${lib.concatStringsSep " " config.server."${config.networking.hostName}".backup-users}; do
              ${lib.concatMapStringsSep "  " (remote: ''
                rsync -aP --mkpath --delete -e "ssh -i /etc/ssh/ssh_host_ed25519_key -o StrictHostKeyChecking=no" /home/"$user"/${config.backup-dir}/ ${config.backup-user-prefix}-${remote}@${config.server."${remote}"."private-ip"}:/home/${config.backup-user-prefix}-${remote}/${config.data-dir}/${config.networking.hostName}/"$user"
              '') (lib.filter (r: r != config.networking.hostName) (lib.attrValues config.hostnames))}
            done

            # Wait for at least 30 seconds before exiting
            while [ $(($(date +%s) - start_time)) -lt 30 ]; do
                sleep 5  # Sleep for a short duration before checking again
            done
          '';
        } + "/bin/sync";
      Restart="on-failure";
      RestartSec="30";
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
