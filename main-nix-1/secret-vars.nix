{ ... }: {
  age.secrets = {
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
  };
}
