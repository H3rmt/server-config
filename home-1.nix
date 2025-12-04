{
  lib,
  config,
  ...
}:
{
  boot = {
    kernel.sysctl = {
      "vm.swappiness" = 2;
      "net.ipv4.ping_group_range" = "0 2000000";
      "net.ipv4.ip_unprivileged_port_start" = 0;
    };
    loader = {
      grub = {
        enable = true;
        device = "/dev/sda";
      };
      efi.canTouchEfiVariables = false;
      efi.efiSysMountPoint = null;
    };
    kernelModules = [ "kvm-intel" ];
    kernelParams = [ "boot.shell_on_fail" ];
    initrd.availableKernelModules = [
      "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi"
    ];
    initrd.kernelModules = [ "nvme" ];
    binfmt.emulatedSystems = [
      "aarch64-linux"
      "armv7l-linux"
    ];
  };

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA5SvynppVEZielnSLJ6CXBdK1umVcedgeYGW7JCI05C";

  fileSystems."/" = {
    device = "/dev/mapper/server2--vg-root";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/sda1";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };
  fileSystems."/home" = {
    device = "/dev/mapper/server2--vg-home";
    fsType = "ext4";
  };

  swapDevices = [{device = "/dev/mapper/server2--vg-swap_1";}];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  networking.nftables.enable = false;
  networking.hostName = "home-1";
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
        8472
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
        "192.168.187.10/32"
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
      matchConfig.PermanentMACAddress = "00:19:99:9f:ee:92";
      linkConfig.Name = "eth0";
    };
  };

  services.k3s = {
    enable = false;
    tokenFile = config.age.secrets.k3s.path;
    role = "server";
    nodeName = "home-1";
    clusterInit = false;

    extraFlags = [
      "--flannel-iface=tailscale0"
      "--node-ip=100.64.0.2"
    ];
  };
}
