{ lib, config, pkgs, ... }:
let
  generatedServices = (map
    (user: {
      "borgmatic_${user}" = {
        description = "Service for Borgmatic ${user} user";
        serviceConfig = {
          Type = "oneshot";
          User = user;
          EnvironmentFile= "${config.age.secrets.borg_pass.path}";
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

  backup = {
    description = "Rscync backups with ssh to other users";
    requires = lib.forEach config.backups."${config.networking.hostName}" (name: "borgmatic_${name}.service");
    after = lib.forEach config.backups."${config.networking.hostName}" (name: "borgmatic_${name}.service");
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellApplication
        {
          name = "collect";
          runtimeInputs = [ pkgs.coreutils pkgs.borgmatic ];
          text = ''
            for user in ${lib.concatStringsSep " " config.backups."${config.networking.hostName}"}; do
              ${lib.concatMapStringsSep "  " (remote: ''
                rsync -aP --delete "/home/$user/${config.backup-dir}@${(builtins.elemAt (builtins.filter (server: server.name == remote) (builtins.attrValues config.server)) 0)."private-ip"}:/home/${config.backup-user-prefix}-${remote}/${config.remote-backup-dir}/${config.networking.hostName}/$user"
              '') (lib.filter (r: r != config.networking.hostName) (lib.attrNames config.backups))}
            done
          '';
        } + "/bin/collect";
    };
  };
in
{
  systemd.services = { inherit backup; } // (lib.foldl' (acc: service: acc // service) {} generatedServices); # merge all generated services

  # systemd.timers."backup" = {
  #   wantedBy = [ "timers.target" ];
  #   timerConfig = {
  #     Unit = "backup.service";
  #     OnBootSec = "120";
  #     RandomizedDelaySec = "5min";
  #     OnCalendar = "*:0";
  #     Persistent = true;
  #   };
  # };
}
