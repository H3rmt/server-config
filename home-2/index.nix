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
    nodeLabel = ["gpu=1"];
    clusterInit = false;
    serverAddr = "https://k3s.h3rmt.dev:6443";
  };
}
