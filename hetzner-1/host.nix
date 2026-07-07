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
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
    # SeaBIOS needs GRUB here; systemd-boot only works with UEFI.
    loader.grub = {
      enable = true;
      efiSupport = false;
      device = "/dev/sda";
    };
    # No host-specific always-on kernel modules needed.
    kernelModules = [ "nvme_fabrics" "nvme_tcp" ];
    kernelParams = [ "boot.shell_on_fail" "nvme_core.multipath=Y" "hugepagesz=2M" "hugepages=1024" ];
    # Minimal storage/virtualization modules required early during boot.
    initrd.availableKernelModules = [
      "ahci" "xhci_pci" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod"
    ];

    # No extra early-boot modules needed.
    initrd.kernelModules = [ ];

    # Run ARM containers/builds via binfmt on x86_64.
    binfmt.emulatedSystems = [
      "aarch64-linux"
      "armv7l-linux"
    ];
  };

  hardware.cpu.amd.updateMicrocode = true;

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ9946IwDuqgDvfZHjpGHdxQSY3nLrk0OjVY2vvJDL2d";

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXROOT";
    fsType = "ext4";
  };
  
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXBOOT";
    fsType = "ext4";
  };

  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
