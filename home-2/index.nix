{
  lib,
  config,
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
      allowedUDPPorts = [ ];
    };
    trustedInterfaces = [
      "wg0"
      "cni0"
      "flannel.1"
    ];
  };

  services.fail2ban.enable = lib.mkForce false;

  services.zfs.autoScrub.enable = true;
  services.openiscsi = {
    enable = true;
    name = "${config.networking.hostName}-initiatorhost";
  };
  systemd.services.iscsid.serviceConfig = {
    PrivateMounts = "yes";
    BindPaths = "/run/current-system/sw/bin:/bin";
  };
  services.k3s = {
    enable = true;
    tokenFile = config.age.secrets.k3s.path;
    role = "agent";
    nodeName = config.networking.hostName;
    nodeLabel = ["gpu=1"];
    clusterInit = false;
    serverAddr = "https://k3s-main.h3rmt.dev:6443";
    extraFlags = [
      "--flannel-iface=wg0"
    ];
  };
}
