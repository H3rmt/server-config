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
        efiSupport = false;
        device = "/dev/sda";
      };
    };
    kernelModules = [ "kvm-intel" ];
    kernelParams = [ "boot.shell_on_fail" ];
    initrd.availableKernelModules = [
      "ata_generic"
      "ehci_pci"
      "ahci"
      "usb_storage"
      "usbhid"
      "xhci_pci"
      "ehci_pci"
      "sd_mod"
    ];
    initrd.kernelModules = [ "amdgpu" ];
    binfmt.emulatedSystems = [
      "aarch64-linux"
      "armv7l-linux"
    ];
  };
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHeAjxCzY56TNLs3oRpAFDrtAhMXdKEAAZTTeBD4p9y8";

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
