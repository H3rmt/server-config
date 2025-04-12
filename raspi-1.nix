{ lib, config, pkgs, ... }:
{
  boot = {
    kernel.sysctl = {
      "vm.swappiness" = 2;
      "net.ipv4.ping_group_range" = "0 2000000";
      "net.ipv4.ip_unprivileged_port_start" = 0;
    };
    loader.grub.enable = false;
    loader.generic-extlinux-compatible.enable = true;
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
    fsType = "ext4";
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/cb20209f-8b3f-4f58-a3b9-ae78cf32fdd6";
    fsType = "ext4";
  };

  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 5 * 1024;
  }];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  services.tailscale = {
    enable = true;
    authKeyParameters.baseURL = "http://headscale.h3rmt.zip:4433";
    openFirewall = true;
  };

  networking.nftables.enable = true;
  networking.hostName = "raspi-1";
  networking.firewall = {
    enable = true;
    rejectPackets = true;
    interfaces."eth0" = {
      allowedTCPPorts = [ 6443 ];
      allowedUDPPorts = [ ];
    };
    trustedInterfaces = [ ];
  };

  # needed for builds
  zramSwap.enable = true;
  zramSwap.memoryPercent = 150;

  services.fail2ban.enable = lib.mkForce false;
  systemd.network = {
    enable = true;
    networks."10-eth" = {
      matchConfig.Name = "eth0";
      dns = [
        "8.8.8.8"
        "8.8.4.4"
        "2001:4860:4860::8888"
        "2001:4860:4860::8844"
      ];
      address = [
        "192.168.187.45/32"
      ];
      routes = [
        { Gateway = "192.168.187.1"; GatewayOnLink = true; }
      ];
      linkConfig.RequiredForOnline = "yes";
    };
    links."10-eth" = {
      matchConfig.PermanentMACAddress = "b8:27:eb:ab:d4:6b";
      linkConfig.Name = "eth0";
    };
  };

  # TODO kiosk
}