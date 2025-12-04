{ config, pkgs, lib, ... }:
{
  services.k3s = {
    enable = true;
    tokenFile = config.age.secrets.k3s.path;
    role = "server";
    nodeName = "ovh-1";
    clusterInit = true;

    extraFlags = [
      "--flannel-iface=tailscale0"
      "--node-ip=100.64.0.2"
    ];
  };
}
