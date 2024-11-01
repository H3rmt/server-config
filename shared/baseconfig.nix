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
}
