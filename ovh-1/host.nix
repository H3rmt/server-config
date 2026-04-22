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

    # UEFI boot setup for this host.
    loader.systemd-boot = {
      enable = true;
    };

    # Kept empty intentionally: kvm-intel was removed because host boot does not
    # require it; it auto-loads when virtualization is actually used.
    kernelModules = [ "nvme_fabrics" "nvme_tcp" ];
    kernelParams = [ "boot.shell_on_fail" "nvme_core.multipath=Y" "hugepagesz=2M" "hugepages=1024" ];

    # Minimal storage/USB modules required early during boot.
    initrd.availableKernelModules = [
      "ahci"
      "xhci_pci"
      "ehci_pci"
      "usbhid"
      "sd_mod"
    ];

    # Required for software RAID assembly in initrd.
    initrd.kernelModules = [ "md_mod" ];

    # Run ARM containers/builds via binfmt on x86_64.
    binfmt.emulatedSystems = [
      "aarch64-linux"
      "armv7l-linux"
    ];

    # This host boots from mdadm software RAID.
    swraid = {
      enable = true;
      mdadmConf = mdadmconfigfile;
    };
  };
  hardware.cpu.intel.updateMicrocode = true;

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
