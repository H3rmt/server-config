{ config, pkgs, ... }:
{
  services.k3s = {
    enable = true;
    role = "server";
    tokenFile = config.age.secrets.k3s.path;
    clusterInit = true;
    extraFlags = [
      "--node-name=ovh-1"
      "--tls-san=ovh-1.h3rmt.internal"
      "--advertise-address=$(tailscale ip -4)"
      "--node-ip=$(tailscale ip -4)"
    ];
  };
  systemd.services.k3s = {
    serviceConfig.ExecStartPre = [
      # Wait for Tailscale to be up
      "${pkgs.coreutils}/bin/sleep 5"
    ];
    environment = {
      K3S_NODE_IP = "$(${pkgs.tailscale}/bin/tailscale ip -4 | head -n1)";
    };
  };
}
