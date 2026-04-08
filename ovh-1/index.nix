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

  networking.nftables.enable = true;
  networking.hostName = "ovh-1";
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
        3000 # temp ai access
        8083 # temp access
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
    role = "server";
    nodeName = config.networking.hostName;
    # Note: This must be true the very first time the cluster is initialized, but must be set to false for subsequent runs.
    clusterInit = false;
    extraFlags = [
      "--flannel-iface=wg0"
      "--tls-san=k3s-main.h3rmt.dev"
      "--node-external-ip=${config.custom.server."ovh-1".public-ip-v4},${config.custom.server."ovh-1".public-ip-v6}"
      "--kube-controller-manager-arg=node-eviction-rate=0.5"
    ];
    manifests = {
      "hetzner-external-dns.yaml".source = config.age.secrets.hetzner-external-dns.path;
      "hetzner-cert-manager.yaml".source = config.age.secrets.hetzner-cert-manager.path;
      "traefik-auth-secret-longhorn".source = config.age.secrets.traefik-auth-secret-longhorn.path;
      "garage-rpc".source = config.age.secrets.garage-rpc.path;
      "garage-webui".source = config.age.secrets.garage-webui.path;
      "grafana-admin".source = config.age.secrets.grafana-admin.path;
      "traefik-auth-secret-alerts".source = config.age.secrets.traefik-auth-secret-alerts.path;
      "authelia".source = config.age.secrets.authelia.path;
      "authelia-redis".source = config.age.secrets.authelia-redis.path;
      "authelia-oidc-secrets".source = config.age.secrets.authelia-oidc-secrets.path;
      "coder-oidc-secret".source = config.age.secrets.coder-oidc-secret.path;
      "lldap".source = config.age.secrets.lldap.path;
    };
  };
}
