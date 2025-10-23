{
  lib,
  config,
  pkgs,
  ...
}:
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

  swapDevices = [
    {
      device = "/var/swapfile";
      size = 5 * 1024;
    }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  networking.nftables.enable = true;
  networking.hostName = "raspi-1";
  networking.firewall = {
    enable = true;
    rejectPackets = true;
    interfaces."tailscale0" = {
      allowedTCPPorts = [
        6443
        2379
        2380
        10250
      ];
      allowedUDPPorts = [
        6443
      ];
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
        "1.1.1.1"
        "8.8.8.8"
        "8.8.4.4"
        "2606:4700:4700::1111"
        "2001:4860:4860::8888"
        "2001:4860:4860::8844"
      ];
      address = [
        "192.168.187.45/32"
      ];
      routes = [
        {
          Gateway = "192.168.187.1";
          GatewayOnLink = true;
        }
      ];
      linkConfig.RequiredForOnline = "yes";
    };
    links."10-eth" = {
      matchConfig.PermanentMACAddress = "b8:27:eb:ab:d4:6b";
      linkConfig.Name = "eth0";
    };
  };

  services.k3s = {
    enable = true;
  };
  systemd.services.k3s = {
    serviceConfig = {
      ExecStartPre = [
        # Wait for Tailscale to be up
        "${pkgs.coreutils}/bin/sleep 5"
      ];
      ExecStart = lib.mkForce ''/bin/sh -c "${pkgs.k3s}/bin/k3s agent \
        --server https://ovh-1.h3rmt.internal:6443 \
        --token-file ${config.age.secrets.k3s.path} \
        --node-name=raspi-1 \
        --node-ip=$(${pkgs.tailscale}/bin/tailscale ip -4)"
      '';
    };
  };

  services.cage = {
    enable = true;
    program = "${pkgs.eog} -wgf /home/kiosk/view.jpg";
    user = "kiosk";
  };
  systemd.services."cage-tty1".after = [
    "network-online.target"
    "systemd-resolved.service"
  ];
  systemd.services."cage-tty1".serviceConfig.Restart = lib.mkForce "always";
}
