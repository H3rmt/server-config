{ inputs, lib, config, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ./secret-vars.nix
    ./home/index.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  boot = {
    loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
      device = "nodev";
    };
    tmp.cleanOnBoot = true;
    kernel.sysctl = {
      "vm.swappiness" = 10;
      "net.ipv4.ip_unprivileged_port_start" = 80;
      "net.ipv4.ping_group_range" = "0 2000000";
    };
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

  time.timeZone = "Europe/Berlin";
  programs.zsh.enable = true;
  zramSwap.enable = true;
  networking.hostName = "main-nix-1";
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
