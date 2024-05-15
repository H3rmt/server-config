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
    allowedTCPPorts = [ 22 80 443 ];
    allowedUDPPorts = [ 443 ];
  };

  time.timeZone = "Europe/Berlin";
  networking.hostName = "main-nix-1";
  networking.domain = "";
}
