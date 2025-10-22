{
  lib,
  config,
  pkgs,
  ...
}:
let
  mdadmconfigfile = ''
    ARRAY /dev/md/0 metadata=1.2 spares=1 UUID=c3ce7f12:483e32b4:eab965cf:ea5463d7
  '';
in
{
  boot = {
    kernel.sysctl = {
      "vm.swappiness" = 2;
      "net.ipv4.ping_group_range" = "0 2000000";
      "net.ipv4.ip_unprivileged_port_start" = 0;
    };
    loader.systemd-boot = {
      enable = true;
    };
    kernelModules = [ "kvm-intel" ];
    kernelParams = [ "boot.shell_on_fail" ];
    initrd.availableKernelModules = [
      "ahci"
      "xhci_pci"
      "ehci_pci"
      "usbhid"
      "sd_mod"
    ];
    initrd.kernelModules = [ "md_mod" ];
    binfmt.emulatedSystems = [
      "aarch64-linux"
      "armv7l-linux"
    ];
    swraid = {
      enable = true;
      mdadmConf = mdadmconfigfile;
    };
  };

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEMgrZX8Qj8sx/knA+naq6yGNKx3nyxGc3kz5RF73zSp";

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXROOT";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXBOOT";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  services.headscale = {
    enable = true;
    address = "0.0.0.0";
    port = 4433;
    settings = {
      server_url = "http://headscale.h3rmt.dev:4433";
      dns = {
        magic_dns = true;
        base_domain = "h3rmt.internal";
        nameservers.global = [
          "1.1.1.1"
          "8.8.8.8"
          "8.8.4.4"
          "2606:4700:4700::1111"
          "2001:4860:4860::8888"
          "2001:4860:4860::8844"
        ];
      };
    };
  };

  services.tailscale = {
    enable = true;
    authKeyParameters.baseURL = "http://headscale.h3rmt.dev:4433";
    openFirewall = false;
    interfaceName = "tailscale0";
  };

  networking.nftables.enable = true;
  networking.hostName = "ovh-1";
  networking.firewall = {
    enable = true;
    rejectPackets = true;
    interfaces."tailscale0" = {
      allowedTCPPorts = [
        6443
        2379
        2380
      ];
      allowedUDPPorts = [
        6443
      ];
    };
    interfaces."eth0" = {
      allowedTCPPorts = [
        4433
        443
        80
      ];
      allowedUDPPorts = [
        443
      ];
    };
  };

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
        "37.187.250.146/32"
        "2001:41d0:c:292::1/128"
      ];
      routes = [
        {
          Gateway = "37.187.250.254";
          GatewayOnLink = true;
        }
        {
          Gateway = "2001:41d0:000c:02ff:00ff:00ff:00ff:00ff";
          GatewayOnLink = true;
        }
      ];
      linkConfig.RequiredForOnline = "yes";
    };
    links."10-eth" = {
      matchConfig.PermanentMACAddress = "0c:c4:7a:6b:0d:98";
      linkConfig.Name = "eth0";
    };
  };
}
