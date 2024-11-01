{ lib, config, pkgs, ... }:
let
  generatedServices = (map
    (user: {
      "borgmatic_${user}" = {
        description = "Service for Borgmatic ${user} user";
        serviceConfig = {
          Type = "oneshot";
          User = user;
          EnvironmentFile = "${config.age.secrets.borg_pass.path}";
          ExecStart = pkgs.writeShellApplication
            {
              name = "borgmatic";
              runtimeInputs = [ pkgs.coreutils pkgs.borgmatic ];
              text = ''
                if [ -z "$(ls -A /home/${user}/${config.backup-dir})" ]; then
                  echo "Starting Initial Borgmatic backup"
                  borgmatic config validate --verbosity 1
                  borgmatic init --encryption repokey-blake2 --verbosity 1
                  borgmatic create --list --stats --verbosity 1
                else
                  echo "Backup directory is not empty, skipping initial backup"
                fi
                borgmatic --stats --list --verbosity 1 --syslog-verbosity 0
              '';
            } + "/bin/borgmatic";
          WorkingDirectory = "/home/${user}";
          Restart="on-failure";
          RestartSec="30";
        };
      };
    })
    config.backups."${config.networking.hostName}");

  backup = {
    description = "Rscync backups with ssh to other users";
    requires = lib.forEach config.backups."${config.networking.hostName}" (name: "borgmatic_${name}.service");
    after = lib.forEach config.backups."${config.networking.hostName}" (name: "borgmatic_${name}.service");
    serviceConfig = {
      Type = "exec";
      ExecStart = pkgs.writeShellApplication
        {
          name = "sync";
          runtimeInputs = [ pkgs.rsync pkgs.openssh ];
          text = ''
            for user in ${lib.concatStringsSep " " config.backups."${config.networking.hostName}"}; do
              ${lib.concatMapStringsSep "  " (remote: ''
                rsync -aP --mkpath --delete -e "ssh -i /etc/ssh/ssh_host_ed25519_key -o StrictHostKeyChecking=no" /home/"$user"/${config.backup-dir}/ ${config.backup-user-prefix}-${remote}@${(builtins.elemAt (builtins.filter (server: server.name == remote) (builtins.attrValues config.server)) 0)."private-ip"}:/home/${config.backup-user-prefix}-${remote}/${config.data-dir}/${config.networking.hostName}/"$user"
              '') (lib.filter (r: r != config.networking.hostName) (lib.attrNames config.backups))}
            done
          '';
        } + "/bin/sync";
      Restart="on-failure";
      RestartSec="30";
    };
  };

  exporter = {
    description = "Service for Systemd Exporter: ${builtins.toJSON (lib.forEach config.backups."${config.networking.hostName}" (name: "borgmatic_${name}.service"))} and backup.service";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = ''
        ${pkgs.prometheus-systemd-exporter}/bin/systemd_exporter \
          --web.listen-address ${config.address.private.systemd-exporter."${config.networking.hostName}"} --systemd.collector.unit-include="${lib.concatStringsSep "|" (lib.forEach config.backups."${config.networking.hostName}" (name: "borgmatic_${name}.service"))}|backup.service|backup.timer"
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
      RandomizedDelaySec = "5min";
      OnCalendar = "*:10";
      Persistent = true;
    };
  };
}
