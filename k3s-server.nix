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
    serverAddr = "https://ovh-1.h3rmt.internal:6443";
  };
}
