{ config, ...} : {
  services.k3s = {
    enable = true;
    role = "agent";
    server = "https://ovh-1.h3rmt.internal:6443"; 
    tokenFile = config.age.secrets.k3s.file;
  };
}