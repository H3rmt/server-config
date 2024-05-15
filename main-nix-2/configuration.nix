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
    enable = false;
    rejectPackets = true;
    interfaces."enp1s0" = {
      allowedTCPPorts = [ config.ports.public.ssh config.ports.public.http config.ports.public.https ];
      allowedUDPPorts = [ config.ports.public.https ];
    };
    interfaces."enp7s0" = {
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
  };

  time.timeZone = "Europe/Berlin";
  networking.hostName = "main-nix-2";
  networking.domain = "h3rmt.zip";
}
