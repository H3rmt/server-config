{ inputs, lib, config, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ./secret-vars.nix
    ./home/index.nix
  ];

  boot = {
    kernel.sysctl = {
      "vm.swappiness" = 2;
      "net.ipv4.ping_group_range" = "0 2000000";
    };
    loader.grub.enable = false;
    loader.generic-extlinux-compatible.enable = true;
  };

  networking.nftables.enable = true;
  networking.hostName = config.hostnames.raspi-1;
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
    listenAddress = builtins.elemAt (lib.splitString ":" config.address.private.wireguard."wireguard-exporter-${config.hostnames.raspi-1}") 0;
    port = lib.strings.toInt (builtins.elemAt (lib.splitString ":" config.address.private.wireguard."wireguard-exporter-${config.hostnames.raspi-1}") 1);
  };

  services.fail2ban.enable = lib.mkForce false;

  # needed for builds
  zramSwap.enable = true;
  zramSwap.memoryPercent = 150;

  # needed for kiosk
  services.cage = {
    enable = true;
    program = "${pkgs.eog} /home/kiosk/view.png"; 
    user = "kiosk";
  };
  systemd.services."cage-tty1".after = [
    "network-online.target"
    "systemd-resolved.service"
  ];
  systemd.services."cage-tty1".serviceConfig.Restart = lib.mkForce "always";
}
