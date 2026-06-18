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
  networking.hostName = "hetzner-1";
  networking.firewall = {
    enable = true;
    rejectPackets = true;
    interfaces."eth0" = {
      allowedTCPPorts = [
        6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
        2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
        2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
        443
        80
      ];
      allowedUDPPorts = [
        443
        8472 # k3s, flannel: required if using multi-node for inter-node networking
        51820 # wireguard
      ];
    };
    trustedInterfaces = [
      "wg0"
      "cni0"
      "flannel.1"
    ];
  };

  services.fail2ban.enable = lib.mkForce false;


  services.k3s = {
    enable = true;
    tokenFile = config.age.secrets.k3s.path;
    role = "server";
    nodeName = config.networking.hostName;
    nodeLabel = [];
    clusterInit = false;
    serverAddr = "https://k3s-main.h3rmt.dev:6443";
    extraFlags = [
      "--flannel-iface=wg0"
      "--tls-san=k3s-main.h3rmt.dev"
      "--node-external-ip=${config.custom.server."hetzner-1".public-ip-v4},${config.custom.server."hetzner-1".public-ip-v6}"
      "--kube-controller-manager-arg=node-eviction-rate=0.5"
    ];
  };
}
