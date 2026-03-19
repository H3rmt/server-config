{
  config,
  ...
}:
{
  imports = [
    ./net.nix
    ./host.nix
    ./secrets.nix
  ];

  networking.nftables.enable = false;
  networking.hostName = "ovh-1";
  networking.firewall = {
    enable = true;
    rejectPackets = true;
    interfaces."eth0" = {
      allowedTCPPorts = [
        6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
        # 2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
        # 2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
        443
        80
      ];
      allowedUDPPorts = [
        443
        8472 # k3s, flannel: required if using multi-node for inter-node networking
        51820 # wireguard
      ];
    };
    trustedInterfaces = [ "wg0" ];
  };

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
    agentTokenFile = config.age.secrets.k3s.path;
    role = "server";
    nodeName = config.networking.hostName;
    clusterInit = true;
    extraFlags = [
      "--flannel-iface=wg0 --tls-san=k3s-main.h3rmt.dev"
      "--node-external-ip=${config.custom.server."ovh-1".public-ip-v4},${config.custom.server."ovh-1".public-ip-v6}"
    ];
    manifests = {
      "hetzner-external-dns.yaml".source = config.age.secrets.hetzner-external-dns.path;
      "hetzner-cert-manager.yaml".source = config.age.secrets.hetzner-cert-manager.path;
      "traefik-auth-secret-longhorn".source = config.age.secrets.traefik-auth-secret-longhorn.path;
    };
  };
}
