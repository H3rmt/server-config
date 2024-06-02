{ age, clib, hostName }: { lib, config, home, pkgs, inputs, ... }: {
  imports = [
    ../usr.nix
  ];
  home.stateVersion = config.nixVersion;

  home.activation.script = clib.create-folders lib [
    "${config.data-prefix}/backups/${config.server.main-1.name}"
    "${config.data-prefix}/backups/${config.server.main-2.name}"
  ];

  # Generate a new SSH key (only if missing => must be updated in config after that)
  home.activation.generateSSHKey = ''
    test -f ${config.home.homeDirectory}/.ssh/id_ed25519 || run ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f ${config.home.homeDirectory}/.ssh/id_ed25519 -N ""
    run chmod 600 ${config.home.homeDirectory}/.ssh/*
  '';

  exported-services = [ "borgmatic.timer" "borgmatic.service" ];

  systemd.user = {
    services = {
      borgmatic = {
        Unit = {
          Description = "Service for Borgmatic";
        };
        Service = {
          ExecStart = pkgs.writeShellApplication
            {
              name = "borgmatic";
              runtimeInputs = [ pkgs.borgmatic ];
              text = ''
                borgmatic \
                  --stats \
                  --list \
                  --verbosity 2 \
                  --syslog-verbosity 1
              '';
            } + /bin/borgmatic;
        };
      };
    };
    timers = {
      borgmatic = {
        Unit = {
          Description = "Timer for Borgmatic";
        };
        Install = {
          WantedBy = [ "timers.target" ];
        };
        Timer = {
          Unit = "borgmatic.service";
          OnCalendar = "*:0/30";
          Persistent = true;
        };
      };
    };
  };

  programs.borgmatic = {
    enable = true;
    backups = {
      user-data = {
        location = {
          patterns = [
            "P sh"
            "R /"
            "! re:^(dev|proc|run|sys|tmp|root)"
            "- **"
            "+ /home/*/${config.data-dir}/**"
            "- /home/${config.backup-user-prefix}-${config.server.main-1.name}/${config.data-dir}/backups"
            "- /home/${config.backup-user-prefix}-${config.server.main-2.name}/${config.data-dir}/backups"
          ];
          repositories = [
            {
              "path" = "ssh://${config.backup-user-prefix}-${config.server.main-1.name}@${config.server.main-1.private-ip}:${toString config.ports.exposed.ssh}/home/${config.backup-user-prefix}-${config.server.main-1.name}/${config.data-dir}/backups/${hostName}";
              "label" = "remote-1";
            }
            {
              "path" = "ssh://${config.backup-user-prefix}-${config.server.main-2.name}@${config.server.main-2.private-ip}:${toString config.ports.exposed.ssh}/home/${config.backup-user-prefix}-${config.server.main-2.name}/${config.data-dir}/backups/${hostName}";
              "label" = "remote-2";
            }
          ];
        };
        retention = {
          keepDaily = 7;
          keepWeekly = 4;
          keepMonthly = 6;
        };
        storage = {
          encryptionPasscommand = "${pkgs.coreutils}/bin/cat '${age.secrets.borg_pass.path}'";
        };
        output.extraConfig = {
          compression = "zstd,15";
        };
      };
    };
  };

  home.file = clib.create-files config.home.homeDirectory {
    "setup.sh" = {
      executable = true;
      text = ''
        set -e 
        set -o pipefail

        chmod 600 ${config.home.homeDirectory}/.ssh/*
        echo "Starting Initial Borgmatic backup"
        borgmatic config validate --verbosity 2
        borgmatic init --encryption repokey-blake2 --verbosity 2
        borgmatic create --list --stats --verbosity 2
      '';
    };
  };
}
