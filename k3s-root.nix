{ config, ... }:
{
  services.k3s = {
    enable = true;
    role = "server";
    tokenFile = config.age.secrets.k3s.path;
    clusterInit = true;
  };
}
