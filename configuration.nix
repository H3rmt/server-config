{ inputs
, outputs
, lib
, config
, pkgs
, ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ./vars.nix
    ./varsmodule.nix
    ./home/index.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.tmp.cleanOnBoot = true;
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
  };
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };

  virtualisation.containers.enable = true;
  virtualisation = {
    podman = {
      enable = true;
      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  programs.zsh.enable = true;
  zramSwap.enable = true;
  networking.hostName = "main-nix-0";
  networking.domain = "";
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
      bantime = "86400";
    };
  };
  system.stateVersion = config.vars.nixVersion;
  # system.copySystemConfiguration = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  users.mutableUsers = false;
  users.defaultUserShell = pkgs.zsh;

  systemd.user.services = {
    certbot = {
      description = "Service for Certbot Renewal";
      serviceConfig = {
        ExecStart = "/home/reverseproxy/renew-certificate.sh";
        User = "reverseproxy";
      };
    };
    uptest = {
      description = "Service for triggering Uptest";
      serviceConfig = {
        ExecStart = "curl http://localhost:8084/check";
        User = "uptest";
      };
    };
  };
  systemd.user.timers = {
    certbot = {
      wantedBy = [ "timers.target" ];
      description = "Timer for Certbot Renewal";
      timerConfig = {
        Unit = "certbot.service";
        OnCalendar = "0/12:00:00";
        RandomizedDelaySec = "1h";
        Persistent = true;
      };
    };
    uptest = {
      wantedBy = [ "timers.target" ];
      description = "Timer for triggering Uptest";
      timerConfig = {
        Unit = "uptest.service";
        OnCalendar = "*-*-* 6:00:00";
        Persistent = true;
      };
    };
  };

  environment.systemPackages = [
    pkgs.git
    pkgs.micro
    pkgs.btop
    pkgs.htop
    pkgs.podman
    pkgs.podman-compose
    pkgs.podman-tui
    pkgs.tmux
    pkgs.fail2ban
    pkgs.curl
    pkgs.zsh
    pkgs.joshuto
  ];
}
