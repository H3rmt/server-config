{ config, pkgs, lib, ... }:
{
  services.k3s = {
    enable = true;
  };
  systemd.services.k3s = {
    serviceConfig = {
      ExecStartPre = [
        # Wait for Tailscale to be up
        "${pkgs.coreutils}/bin/sleep 5"
      ];
      ExecStart = lib.mkForce "/bin/sh -c '${pkgs.k3s}/bin/k3s server \
        --tls-san=ovh-1.h3rmt.internal \
        --node-name=ovh-1 \
        --cluster-init \
        --token-file ${config.age.secrets.k3s.path} \
        --advertise-address=$(tailscale ip -4) \
        --node-ip=$(tailscale ip -4)'
      ";
    };
  };
}
