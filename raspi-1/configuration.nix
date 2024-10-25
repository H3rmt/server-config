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
  networking.hostName = config.server.raspi-1.name;
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
    program = "${pkgs.ungoogled-chromium}/bin/chromium --enable-features=UseOzonePlatform --ozone-platform=wayland --kiosk https://ennexos.sunnyportal.com/";
    user = "kiosk";
  };
  systemd.services."cage-tty1".after = [
    "network-online.target"
  ];
}
