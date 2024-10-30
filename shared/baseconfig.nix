{ inputs, lib, config, pkgs, ... }: {
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  boot.tmp.cleanOnBoot = true;

  virtualisation = {
    podman = {
      enable = true;
      defaultNetwork.settings = {
        dns_enabled = true;
      };
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = [ "--all" ];
      };
    };
  };
  systemd.user.services.podman.environment = { LOGGING = "--log-level=warn"; };

  programs.zsh.enable = true;
  zramSwap.enable = true;
  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
      };
    };
    logind.killUserProcesses = false;
    fail2ban = {
      enable = true;
      bantime = "12h";
      ignoreIP = [
        "10.0.0.0/8"
        "172.16.0.0/12"
        "192.168.0.0/16"
      ];
      bantime-increment.enable = true;
      bantime-increment.rndtime = "20m";
      bantime-increment.maxtime = "2d";
    };
  };

  system.stateVersion = config.nixVersion;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  security.pam.loginLimits = [{
    domain = "*";
    type = "soft";
    item = "nofile";
    value = "8192";
  }];

  time.timeZone = "Europe/Berlin";
  networking.domain = config.main-url;
  networking.useDHCP = false;

  environment.memoryAllocator.provider = "scudo";
  security.protectKernelImage = true;
  security.sudo.enable = false;

  environment.systemPackages = [
    pkgs.git
    pkgs.micro
    pkgs.btop
    pkgs.htop
    pkgs.podman
    pkgs.podman-compose
    pkgs.podman-tui
    pkgs.passt
    pkgs.tmux
    pkgs.fail2ban
    pkgs.curl
    pkgs.wget
    pkgs.zsh
    pkgs.pure-prompt
    pkgs.unzip
    pkgs.tree
    pkgs.joshuto
    pkgs.zoxide
    pkgs.fzf
    pkgs.eza
    pkgs.ripgrep
    pkgs.nix-output-monitor
    pkgs.dig
    pkgs.jq
    pkgs.openssl
    pkgs.nmap
    pkgs.borgbackup
    pkgs.prometheus-systemd-exporter
    pkgs.acl
    pkgs.wireguard-tools
    inputs.agenix.packages.aarch64-linux.default
  ];

  # systemd.services = (lib.genAttrs (lib.attrNames config.backups."${config.networking.hostName}") (user: {
  #   description = "Service for Borgmatic ${user}";
  #   serviceConfig = {
  #     Type = "oneshot";
  #     User = user;
  #     ExecStart = pkgs.writeShellApplication {
  #       name = "borgmatic";
  #       runtimeInputs = [ pkgs.coreutils pkgs.borgmatic ];
  #       text = ''
  #         if [ -z "$(ls -A /home/${user}/${config.backup-dir})" ]; then
  #           echo "Starting Initial Borgmatic backup"
  #           borgmatic config validate --verbosity 1
  #           borgmatic init --encryption repokey-blake2 --verbosity 1
  #           borgmatic create --list --stats --verbosity 1
  #         else
  #           echo "Backup directory is not empty, skipping initial backup"
  #         fi

  #         borgmatic --stats --list --verbosity 1 --syslog-verbosity 0
  #       '';
  #     } + "/bin/borgmatic";
  #     WorkingDirectory = "/home/${user}";
  #   };
  # }));
  systemd.services."backup" = {
    description = "Collect backups";
    after = [ (lib.attrNames config.backups."${config.networking.hostName}") ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellApplication {
        name = "collect";
        runtimeInputs = [ pkgs.coreutils pkgs.borgmatic ];
        text = ''
          for user in ${lib.concatStringsSep " " (lib.attrNames config.backups."${config.networking.hostName}")}; do
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
  
  systemd.services."rsync" = let 
    getPrivateIP = serverName: let
      matchedServers = builtins.filter (server: server.name == serverName) (builtins.attrValues config.server);
    in
      if builtins.length matchedServers > 0 then
        matchedServers[0]."private-ip"
      else
        null;
  in {
    description = "Rscync backups with ssh to other users";
    after = [ "backup.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "${config.backup-user-prefix}-${config.networking.hostName}";
      ExecStart = pkgs.writeShellApplication {
        name = "sync";
        runtimeInputs = [ pkgs.coreutils pkgs.rsync ];
          text = ''
            ${lib.concatMapStringsSep "\n" (remote: ''
              rsync -aP --delete /home/${config.backup-user-prefix}-${config.networking.hostName}/${config.backup-dir}/ ${config.backup-user-prefix}-${remote}@${getPrivateIP remote}:/home/${config.backup-user-prefix}-${remote}/${config.remote-backup-dir}/${config.networking.hostName}/
            '') (lib.filter (r: r != config.networking.hostName) (lib.attrNames config.backups))}
          '';
      } + "/bin/sync";
      WorkingDirectory = "/home/${config.backup-user-prefix}-${config.networking.hostName}";
    };
  };

  # systemd.timers."backup" = {
  #   wantedBy = [ "timers.target" ];
  #   timerConfig = {
  #     Unit = "backup.service";
  #     OnBootSec = "120";
  #     RandomizedDelaySec = "180";
  #     OnCalendar = "*:0";
  #     Persistent = true;
  #   };
  # };
}
