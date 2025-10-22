{ config, ... }:
{
  services.k3s = {
    enable = true;
    role = "server";
    tokenFile = config.age.secrets.k3s.file;
    extraFlags = toString [
      "--debug" # Optionally add additional args to k3s
    ];
    clusterInit = true;
  };
}
