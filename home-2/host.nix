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
    # loader = {
      # grub = {
        # enable = true;
        # efiSupport = false;
        # device = "/dev/sda";
      # };
    # };
    # UEFI boot setup for this host.
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    # Keep explicit because this host mounts ZFS datasets.
    supportedFilesystems = [ "zfs" ];
    kernelModules = [ ];
    kernelParams = [ "boot.shell_on_fail" "ibt=off" ];

    # Minimal storage/USB modules required early during boot.
    initrd.availableKernelModules = [
      "ahci"
      "xhci_pci"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];

    # Nvidia
    # initrd.kernelModules = [ "nvidia" "i915" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
    initrd.kernelModules = [];

    # Run ARM containers/builds via binfmt on x86_64.
    binfmt.emulatedSystems = [
      "aarch64-linux"
      "armv7l-linux"
    ];
  };

  nixpkgs.config.allowUnfree = true;

  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    powerManagement.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };
  hardware.cpu.intel.updateMicrocode = true;
  
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
  fileSystems."/mnt/tank" = {
    device = "tank";
    fsType = "zfs";
  };
  fileSystems."/mnt/tank-garage" = {
    device = "tank/garage";
    fsType = "zfs";
  };

  swapDevices = [{
    device = "/.swapfile";
    size = 8 * 1024; # 8GB
  }];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
