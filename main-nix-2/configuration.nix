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
      "net.ipv4.ip_forward" = 1;
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
    trustedInterfaces = [ "eth1" "wg0" ];
  };

  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ config.server.main-2.private-ip ];
      privateKey = serverPrivateKey;
      listenPort = config.ports.exposed.wireguard;
      peers = [
        {
          publicKey = "<client_public_key>";
          allowedIPs = [ config.server.raspi-1.private-ip ];
        }
      ];
    };
  };

  time.timeZone = "Europe/Berlin";
  networking.hostName = config.server.main-2.name;
  networking.domain = config.main-url;
  networking.useDHCP = false;

  environment.memoryAllocator.provider = "graphene-hardened";
  security.protectKernelImage = true;
  security.sudo.enable = false;
}
