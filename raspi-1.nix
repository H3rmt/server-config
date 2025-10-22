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

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIChc0OADBHo5eqE4tcVHglCGzUvHSTZ6LeC0RcGQ9V6C";

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-label/NIXHOME";
    fsType = "ext4";
  };

  swapDevices = [{
    device = "/var/swapfile";
    size = 5 * 1024;
  }];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  services.tailscale = {
    enable = true;
    authKeyParameters.baseURL = "http://headscale.h3rmt.dev:4433";
    openFirewall = true;
  };

  networking.nftables.enable = true;
  networking.hostName = "raspi-1";
  networking.firewall = {
    enable = true;
    rejectPackets = true;
    interfaces."tailscale0" = {
      allowedTCPPorts = [ 6443 2379 2380 ];
      allowedUDPPorts = [ 6443 ];
    };
    interfaces."eth0" = {
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
    trustedInterfaces = [ ];
  };

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