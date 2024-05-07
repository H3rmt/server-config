{ ... }: {
  age.secrets = {
    root_pass = {
      file = ./secrets/root_pass.age;
      owner = "root";
    };
  };
}
