{ inputs, lib, config, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ./secret-vars.nix
    ./users.nix
  ];

  boot = {
    kernel.sysctl = {
      "vm.overcommit_memory" = 1;
      "vm.swappiness" = 10;
      "net.ipv4.ping_group_range" = "0 2000000";
      "net.ipv4.ip_unprivileged_port_start" = 0;
      "net.ipv4.ip_forward" = 1;
    };
    loader.systemd-boot = {
      enable = true;
    };
  };

  networking.nftables.enable = true;
  networking.hostName = config.hostnames.ovh-1;
  networking.firewall = {
    enable = true;
    rejectPackets = true;
    interfaces."eth0" = {
      allowedTCPPorts = [ config.ports.exposed.http config.ports.exposed.https ];
      allowedUDPPorts = [ config.ports.exposed.https config.ports.exposed.wireguard ];
    };
    trustedInterfaces = [ "wg0" ];
  };

  services.prometheus.exporters.wireguard = {
    enable = true;
    withRemoteIp = true;
    listenAddress = builtins.elemAt (lib.splitString ":" config.address.private.wireguard."wireguard-exporter-${config.hostnames.ovh-1}") 0;
    port = lib.strings.toInt (builtins.elemAt (lib.splitString ":" config.address.private.wireguard."wireguard-exporter-${config.hostnames.ovh-1}") 1);
  };
}
