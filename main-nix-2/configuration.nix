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
      "net.ipv4.ping_group_range" = "0 2000000";
      "net.ipv4.ip_unprivileged_port_start" = 0;
    };
    loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
      device = "nodev";
    };
  };

  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    rejectPackets = true;
    interfaces."eth0" = {
      allowedTCPPorts = [ config.ports.exposed.http config.ports.exposed.https config.ports.exposed.tor-middle config.ports.exposed.tor-middle-dir ];
      allowedUDPPorts = [ config.ports.exposed.https config.ports.exposed.wireguard ];
    };
    trustedInterfaces = [ "wg0" ];
  };

  services.prometheus.exporters.wireguard = {
    enable = true;
    withRemoteIp = true;
    listenAddress = builtins.elemAt (lib.splitString ":" config.address.private.wireguard."wireguard-exporter-${config.server.main-2.name}") 0;
    port = lib.strings.toInt (builtins.elemAt (lib.splitString ":" config.address.private.wireguard."wireguard-exporter-${config.server.main-2.name}") 1);
  };

  time.timeZone = "Europe/Berlin";
  networking.hostName = config.server.main-2.name;
  networking.domain = config.main-url;
  networking.useDHCP = false;

  environment.memoryAllocator.provider = "graphene-hardened";
  security.protectKernelImage = true;
  security.sudo.enable = false;
}
