{ inputs, outputs, lib, config, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ./vars.nix
    ./home/index.nix
  ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.tmp.cleanOnBoot = true;
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "net.ipv4.ip_unprivileged_port_start" = 80;
    "net.ipv4.ping_group_range" = "0 2000000";
  };
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };

  networking.nftables.enable = true;
  networking.firewall = {
    rejectPackets = true;
    logRefusedPackets = true;
    enable = false;
    allowedTCPPorts = [ 22 80 443 ];
    allowedUDPPorts = [ 443 ];
  };

  virtualisation.containers.enable = true;
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
  system.stateVersion = config.nixVersion;
  # system.copySystemConfiguration = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  users.mutableUsers = false;
  # users.defaultUserShell = pkgs.zsh;

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
    pkgs.passt
    pkgs.tmux
    pkgs.fail2ban
    pkgs.curl
    pkgs.wget
    pkgs.zsh
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
    inputs.agenix.packages.aarch64-linux.default
  ];
}
