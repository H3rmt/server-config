{ modulesPath, lib, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];
  boot.initrd.kernelModules = [ "nvme" ];

  fileSystems."/" = { device = "/dev/md3"; fsType = "ext4"; };
  fileSystems."/boot" = { device = "/dev/disk/by-uuid/0632-FF80"; fsType = "vfat"; };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
