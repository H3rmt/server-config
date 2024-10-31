{ lib, config, pkgs, ... }:
let
  generatedServices = (map
    (user: {
      "borgmatic_${user}.service" = {
        description = "Service for Borgmatic ${user}";
        serviceConfig = {
          Type = "oneshot";
          User = user;
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
        };
      };
    })
    config.backups."${config.networking.hostName}");


  rsync = {
    description = "Rscync backups with ssh to other users";
    after = [ "backup.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "${config.backup-user-prefix}-${config.networking.hostName}";
      ExecStart = pkgs.writeShellApplication
        {
          name = "sync";
          runtimeInputs = [ pkgs.coreutils pkgs.rsync ];
          text = ''
            ${lib.concatMapStringsSep "\n" (remote: ''
              rsync -aP --delete /home/${config.backup-user-prefix}-${config.networking.hostName}/${config.backup-dir}/${config.backup-user-prefix}-${remote}@${(builtins.elemAt (builtins.filter (server: server.name == remote) (builtins.attrValues config.server)) 0)."private-ip"}:/home/${config.backup-user-prefix}-${remote}/${config.remote-backup-dir}/${config.networking.hostName}
            '') (lib.filter (r: r != config.networking.hostName) (lib.attrNames config.backups))}
          '';
        } + "/bin/sync";
      WorkingDirectory = "/home/${config.backup-user-prefix}-${config.networking.hostName}";
    };
  };

  backup = {
    description = "Collect backups";
    after = lib.forEach config.backups."${config.networking.hostName}" (name: "${name}.service");
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellApplication
        {
          name = "collect";
          runtimeInputs = [ pkgs.coreutils pkgs.borgmatic ];
          text = ''
            for user in ${lib.concatStringsSep " " config.backups."${config.networking.hostName}"}; do
              if [ -d "/home/${config.backup-user-prefix}-${config.networking.hostName}/${config.backup-dir}/$user" ]; then
                mkdir -p /home/${config.backup-user-prefix}-${config.networking.hostName}/${config.backup-dir}/$user
                cp -r /home/$user/${config.backup-dir}/* /home/${config.backup-user-prefix}-${config.networking.hostName}/${config.backup-dir}/$user/
                chown -R ${config.backup-user-prefix}-${config.networking.hostName}:${config.backup-user-prefix}-${config.networking.hostName} /home/${config.backup-user-prefix}-${config.networking.hostName}/${config.backup-dir}/$user
              fi
            done
          '';
        } + "/bin/collect";
    };
  };
in
{
  systemd.services = { inherit backup; inherit rsync; } // (lib.foldl' (acc: service: acc // service) {} generatedServices); # merge all generated services
}
