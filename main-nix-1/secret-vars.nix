{ ... }: {
  age.secrets = {
    borg_pass = {
      file = ./secrets/borg_pass.age;
      owner = "root";
    };
    root_pass = {
      file = ./secrets/root_pass.age;
      owner = "root";
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
  };
}
