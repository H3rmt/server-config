{ config, ... }: {
  age.secrets = {
    "borg_pass_${config.hostnames.main-1}" = {
      file = ./secrets/borg/main-nix-1.age;
      owner = "${config.backup-user-prefix}-${config.networking.hostName}";
    };
    "borg_pass_${config.hostnames.main-2}" = {
      file = ./secrets/borg/main-nix-2.age;
      owner = "${config.backup-user-prefix}-${config.networking.hostName}";
    };
    "borg_pass_${config.hostnames.raspi-1}" = {
      file = ./secrets/borg/raspi-1.age;
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
    filesharing_admin_pass = {
      file = ./secrets/filesharing/admin_pass.age;
      owner = "filesharing";
    };
    filesharing_admin_email = {
      file = ./secrets/filesharing/admin_email.age;
      owner = "filesharing";
    };
    filesharing_user_pass = {
      file = ./secrets/filesharing/user_pass.age;
      owner = "filesharing";
    };
    nextcloud_maria_root_pass = {
      file = ./secrets/nextcloud/maria_root_pass.age;
      owner = "nextcloud";
    };
    nextcloud_maria_pass = {
      file = ./secrets/nextcloud/maria_pass.age;
      owner = "nextcloud";
    };
    nextcloud_admin_pass = {
      file = ./secrets/nextcloud/admin_pass.age;
      owner = "nextcloud";
    };
    sunny_password = {
      file = ./secrets/sunny_password.age;
      owner = "puppeteer-sma";
    };
  };
}
