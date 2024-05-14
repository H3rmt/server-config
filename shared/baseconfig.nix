{ inputs, lib, config, pkgs, ... }: {
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };
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
      bantime = "5h";
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
