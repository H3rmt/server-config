{ modulesPath, lib, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];
  boot.initrd.kernelModules = [ "nvme" ];
  boot.kernelModules = [ "kvm-intel" ];

  fileSystems."/" = { device = "/dev/md2"; fsType = "ext4"; };
  fileSystems."/boot" = { device = "/dev/md1"; fsType = "vfat"; };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
