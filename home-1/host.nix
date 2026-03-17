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
}
