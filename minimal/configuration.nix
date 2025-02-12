{ inputs, lib, config, pkgs, ... }: {
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  imports = [
    ./hardware-configuration.nix
  ];

  boot = {
    kernel.sysctl = {
      "vm.swappiness" = 10;
      "net.ipv4.ping_group_range" = "0 2000000";
      "net.ipv4.ip_unprivileged_port_start" = 0;
    };
    # loader.systemd-boot = {
    #   enable = true;
    # };
    loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
      device = "nodev";
    };
    tmp.cleanOnBoot = true;
  };


  time.timeZone = "Europe/Berlin";
  networking.useDHCP = true; # no systemd networking to work in chroot 
  networking.domain = config.main-url;
  systemd.network.enable = false;
  system.stateVersion = config.nixVersion;

  environment.systemPackages = [
    pkgs.git
    pkgs.micro
    pkgs.btop
    pkgs.htop
    pkgs.tmux
    pkgs.curl
    pkgs.wget
    pkgs.unzip
    pkgs.tree
    pkgs.joshuto
    pkgs.ripgrep
    pkgs.nix-output-monitor
    pkgs.dig
    pkgs.jq
    inputs.agenix.packages.${pkgs.system}.default
    pkgs.borgbackup
  ];

  users.mutableUsers = false;
  users.users.root = {
    openssh = {
      authorizedKeys.keys = [
        config.my-public-key
      ];
    };
    isSystemUser = true;
    hashedPassword = "$6$/P2qgCx3wxHIcZzN$nPBYexKPD.4eGGO0eBZSnyin6e1uW4VYvsh0nrfunaJ0/bq6O9IEGvN5EZHQ/b5Q7bImGm1s/PRdxT2cpharT1";
  };
}
