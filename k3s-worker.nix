{ config, ... }:
{
  services.k3s = {
    enable = true;
    role = "agent";
    tokenFile = config.age.secrets.k3s.file;
    serverAddr = "https://raspi-1.h3rmt.internal:6443";
  };
}
