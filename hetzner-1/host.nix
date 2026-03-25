{
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

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
    # initrd.availableKernelModules = [
    #   "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi"
    #   "ahci" "xhci_pci" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod"
    # ];
    initrd.availableKernelModules = [ "xhci_pci" "virtio_pci" "virtio_scsi" "usbhid" "sr_mod" ];
    initrd.kernelModules = [ ];
    binfmt.emulatedSystems = [
      "aarch64-linux"
      "armv7l-linux"
    ];
  };

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILsA+zdsqrMa+VLReU6YZ4n+he1A9cTOYudgKGJ1aIz/";

  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };
  
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXBOOTEFI";
    fsType = "vfat";
  };

  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
