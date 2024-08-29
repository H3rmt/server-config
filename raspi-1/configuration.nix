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
    };
    loader.grub.enable = false;
    loader.generic-extlinux-compatible.enable = true;
  };

  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    rejectPackets = true;
    interfaces."eth0" = {
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
    trustedInterfaces = [ "wg0" ];
  };

  services.prometheus.exporters.wireguard = {
    enable = true;
    withRemoteIp = true;
    listenAddress = builtins.elemAt (lib.splitString ":" config.address.private.wireguard."wireguard-exporter-${config.server.raspi-1.name}") 0;
    port = lib.strings.toInt (builtins.elemAt (lib.splitString ":" config.address.private.wireguard."wireguard-exporter-${config.server.raspi-1.name}") 1);
  };

  services.fail2ban.enable = lib.mkForce false;

  # needed for builds
  zramSwap.memoryPercent = 200;

  # needed for kiosk
  services.cage = {
    enable = true;
    program = "${pkgs.firefox}/bin/firefox -kiosk -private-window https://${config.sites.grafana}.${config.main-url}";
    user = "kiosk";
  };
  systemd.services."cage-tty1".after = [
    "network-online.target"
  ];

  time.timeZone = "Europe/Berlin";
  networking.hostName = config.server.raspi-1.name;
  networking.domain = config.main-url;
  networking.useDHCP = false;

  environment.memoryAllocator.provider = "graphene-hardened";
  security.protectKernelImage = true;
  security.sudo.enable = false;
}
