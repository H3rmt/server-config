{ age, clib, hostName }: { lib, config, home, pkgs, inputs, ... }: {
  imports = [
    ../usr.nix
  ];
  home.stateVersion = config.nixVersion;

  home.activation.script = clib.create-folders lib [
    "${config.data-prefix}/backups/${config.server.main-1.name}"
    "${config.data-prefix}/backups/${config.server.main-2.name}"
    "${config.data-prefix}/backups/${config.server.raspi-1.name}"
    "${config.data-prefix}/backup"
  ];

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
              runtimeInputs = [ pkgs.coreutils pkgs.borgmatic ];
              text = ''
                borgmatic \
                  --stats \
                  --list \
                  --verbosity 1 \
                  --syslog-verbosity 0
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
          OnBootSec = "2min";
          RandomizedDelaySec = "9m";
          OnCalendar = "*:0";
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
          sourceDirectories = config.backups."${hostName}";
          repositories = [
            {
              "path" = "${config.home.homeDirectory}/${config.data-dir}/backup";
              "label" = "local";
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

        echo "Starting Initial Borgmatic backup"
        borgmatic config validate --verbosity 2
        borgmatic init --encryption repokey-blake2 --verbosity 2
        borgmatic create --list --stats --verbosity 2
      '';
    };
  };
}
