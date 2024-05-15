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
    reverseproxy_hetzner_token = {
      file = ./secrets/reverseproxy/hetzner_token.age;
      owner = "reverseproxy";
    };
  };
}
