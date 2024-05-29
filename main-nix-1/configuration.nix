{ inputs, lib, config, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ./secret-vars.nix
    ./home/index.nix
  ];

  boot = {
    kernel.sysctl = {
      "vm.overcommit_memory" = 1;
      "vm.swappiness" = 10;
      "net.ipv4.ip_unprivileged_port_start" = 0;
      "net.ipv4.ping_group_range" = "0 2000000";
    };
  };

  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    rejectPackets = true;
    interfaces."eth0" = {
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
    trustedInterfaces = [ "eth1" ];
  };

  time.timeZone = "Europe/Berlin";
  networking.hostName = "main-nix-1";
  networking.domain = config.main-url;
  networking.useDHCP = false;

  environment.memoryAllocator.provider = "graphene-hardened";
  security.protectKernelImage = true;
  security.sudo.enable = false;
}
