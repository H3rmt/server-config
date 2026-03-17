{
  lib,
  config,
  ...
}:
{
  imports = [
    ./net.nix
    ./host.nix
  ];

  networking.nftables.enable = false;
  networking.hostName = "home-1";
  networking.firewall = {
    enable = true;
    rejectPackets = true;
    interfaces."eth0" = {
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
    trustedInterfaces = [ "wg0" ];
  };

  services.fail2ban.enable = lib.mkForce false;

  services.openiscsi = {
    enable = true;
    name = "${config.networking.hostName}-initiatorhost";
  };
  services.k3s = {
    enable = true;
    tokenFile = config.age.secrets.k3s.path;
    role = "agent";
    nodeName = config.networking.hostName;
    clusterInit = false;
    serverAddr = "https://k3s-main.h3rmt.internal:6443";
    extraFlags = [
      "--flannel-iface=wg0"
    ];
  };
}
