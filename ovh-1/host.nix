{
  lib,
  config,
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
}
