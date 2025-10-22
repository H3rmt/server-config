{ config, ... }:
{
  services.k3s = {
    enable = true;
    role = "agent";
    tokenFile = config.age.secrets.k3s.path;
    serverAddr = "https://ovh-1.h3rmt.internal:6443";
  };
}
