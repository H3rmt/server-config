{
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./net.nix
    ./host.nix
    ./secrets.nix
  ];

  networking.nftables.enable = true;
  networking.hostName = "home-2";
  networking.hostId = "7d4d5121";
  networking.firewall = {
    enable = true;
    rejectPackets = true;
    interfaces."eth0" = {
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ 
        5353  # mDNS
        9522  # SMA Speedwire
      ];
    };
    trustedInterfaces = [
      "cni0"
      "flannel-wg"
      "flannel-wg-v6"
    ];
  };

  services.fail2ban.enable = lib.mkForce false;
  services.zfs.autoScrub.enable = true;

  services.k3s = {
    enable = true;
    tokenFile = config.age.secrets.k3s.path;
    role = "agent";
    nodeName = "${config.networking.hostName}.${config.networking.domain}";
    nodeLabel = ["nvidia.com/gpu.present=true" "thread-usb=1" "location=home" "size=large"];
    clusterInit = false;
    serverAddr = "https://k3s.h3rmt.dev:6443";
  };

  hardware.bluetooth.enable = true;

  # NVIDIA 
  services.xserver = {
    enable = false;
    videoDrivers = ["nvidia"];
  };
  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    powerManagement.enable = false;
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    nvidiaPersistenced = true;
  };
  hardware.nvidia-container-toolkit.enable = true;
  hardware.nvidia-container-toolkit.mount-nvidia-executables = true;

  virtualisation.docker.enableNvidia = true;
  services.k3s.containerdConfigTemplate = ''
    {{ template "base" . }}
  
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia]
      privileged_without_host_devices = false
      runtime_engine = ""
      runtime_root = ""
      runtime_type = "io.containerd.runc.v2"
  
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia.options]
      BinaryName = "${pkgs.nvidia-container-toolkit.tools}/bin/nvidia-container-runtime.cdi"
  '';
}
