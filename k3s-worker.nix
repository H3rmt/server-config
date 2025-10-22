{ config, pkgs, ... }:
{
  services.k3s = {
    enable = true;
    role = "server";
    tokenFile = config.age.secrets.k3s.path;
    serverAddr = "https://ovh-1.h3rmt.internal:6443";
    extraFlags = [
      "--node-name=raspi-1"
      "--node-ip=\${K3S_NODE_IP}"
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
