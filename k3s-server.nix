{ config, pkgs, lib, ... }:
{
  systemd.services.k3s = {
    serviceConfig = {
      ExecStartPre = [
        "${pkgs.coreutils}/bin/sleep 3"
      ];
    };
  };
  services.k3s = {
    enable = true;
    tokenFile = config.age.secrets.k3s.path;
    role = "server";
    nodeName = "node-1";
    clusterInit = false;
    serverAddr = "https://100.64.0.2:6443";
  };
}
