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
      "net.ipv4.ip_unprivileged_port_start" = 80;
      "net.ipv4.ping_group_range" = "0 2000000";
    };
  };

  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    rejectPackets = true;
    interfaces."eth0" = {
      allowedTCPPorts = [ config.ports.exposed.http config.ports.exposed.https config.ports.exposed.tor-middle config.ports.exposed.tor-middle-dir ];
      allowedUDPPorts = [ config.ports.exposed.https ];
    };
    interfaces."eth1" = {
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
  };

  time.timeZone = "Europe/Berlin";
  networking.hostName = "main-nix-2";
  networking.domain = config.main-url;
  networking.useDHCP = false;

  environment.memoryAllocator.provider = "graphene-hardened";
  security.protectKernelImage = true;
  security.sudo.enable = false;

  services.prometheus.exporters.systemd = {
    enable = true;
    extraFlags = [ "--systemd.collector.user" "--systemd.collector.enable-restart-count" ];
    port = config.ports.private.systemd-exporter;
  };
}
