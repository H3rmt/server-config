{ config, ...} : {
  services.k3s = {
    enable = true;
    role = "agent";
    tokenFile = config.age.secrets.k3s.file;
    extraFlags = toString [
      "--debug" # Optionally add additional args to k3s
    ];
    serverAddr = "https://raspi-1.h3rmt.internal:6443"; 
  };
}