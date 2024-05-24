{ inputs, lib, config, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ./secret-vars.nix
    ./home/index.nix
  ];

  boot = {
    kernel.sysctl = {
      "vm.swappiness" = 10;
      "net.ipv4.ip_unprivileged_port_start" = 80;
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
    interfaces."eth1" = {
      allowedTCPPorts = [
        config.ports.public.filesharing
        config.ports.public.nextcloud
        config.ports.private.node-exporter-1
        config.ports.private.podman-exporter.filesharing
        config.ports.private.podman-exporter.nextcloud
        config.ports.private.podman-exporter.node-exporter-1
      ];
      allowedUDPPorts = [ ];
    };
  };

  time.timeZone = "Europe/Berlin";
  networking.hostName = "main-nix-1";
  networking.domain = config.main-url;
  networking.useDHCP = false;

  environment.memoryAllocator.provider = "graphene-hardened";
  security.protectKernelImage = true;
  security.sudo.enable = false;
}
