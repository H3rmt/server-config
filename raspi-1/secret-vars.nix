{ config, ... }: {
  age.secrets = {
    borg_pass = {
      file = ./secrets/borg_pass.age;
      owner = "${config.backup-user-prefix}-${config.networking.hostName}";
    };
    root_pass = {
      file = ./secrets/root_pass.age;
      owner = "root";
    };
    wireguard_private = {
      file = ./secrets/wireguard_private.age;
      owner = "root";
      group = "systemd-network";
      mode = "640";
    };
  };
}
