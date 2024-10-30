{ age, clib, hostName }: { lib, config, home, pkgs, inputs, ... }: {
  imports = [
    ../baseuser.nix
  ];
  home.stateVersion = config.nixVersion;

  home.activation.script = clib.create-folders lib [
    "${config.data-prefix}/${config.backup-dir}"
    "${config.data-prefix}/${config.remote-backup-dir}"
  ];

  exported-services = [ "borgmatic.timer" "borgmatic.service" ];

  systemd.user = {
    services."borgmatic-${user}" = {
      Unit = {
        Description = "Service for Borgmatic ${user}";
      };
      Service = {
        Type = "oneshot";
        User = user;
        WorkingDirectory = "/${user}";
        ExecStart = pkgs.writeShellApplication
          {
            name = "borgmatic";
            runtimeInputs = [ pkgs.coreutils pkgs.borgmatic ];
            text = ''
              echo "Starting Initial Borgmatic backup"
              borgmatic config validate --verbosity 1
              borgmatic init --encryption repokey-blake2 --verbosity 1
              borgmatic create --list --stats --verbosity 1

              borgmatic --stats --list --verbosity 1 --syslog-verbosity 0
            '';
          } + /bin/borgmatic;
      };
    };
    timers."borgmatic-${user}" = {
      Unit = {
        Description = "Timer for Borgmatic ${user}";
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
      Timer = {
        Unit = "borgmatic.service";
        OnBootSec = "120";
        RandomizedDelaySec = "180";
        OnCalendar = "*:0";
        Persistent = true;
      };
    };
  };
}
