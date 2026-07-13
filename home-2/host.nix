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
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
      "net.ipv6.conf.all.accept_ra" = 2;
      "net.ipv6.conf.all.accept_ra_rt_info_max_plen" = 64;
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
    kernelModules = [ "nvme_fabrics" "nvme_tcp" ];
    kernelParams = [ "boot.shell_on_fail" "nvme_core.multipath=Y" "hugepagesz=2M" "hugepages=1024" ];

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

  services.xserver.enable = false;
  services.xserver.videoDrivers = ["nvidia"];
  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    powerManagement.enable = false;
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    nvidiaPersistenced = true;
  };
  hardware.cpu.intel.updateMicrocode = true;
  hardware.nvidia-container-toolkit.enable = true;
  hardware.nvidia-container-toolkit.mount-nvidia-executables = true;
  
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
