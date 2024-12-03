{ config, ... }: {
  age.secrets = {
    "borg_pass_${config.hostnames.main-1}" = {
      file = ./secrets/borg/main-nix-1.age;
      owner = "${config.backup-user-prefix}-${config.hostname}";
    };
    "borg_pass_${config.hostnames.main-2}" = {
      file = ./secrets/borg/main-nix-2.age;
      owner = "${config.backup-user-prefix}-${config.hostname}";
    };
    "borg_pass_${config.hostnames.raspi-1}" = {
      file = ./secrets/borg/raspi-1.age;
      owner = "${config.backup-user-prefix}-${config.hostname}";
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
