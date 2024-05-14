{ ... }: {
  age.secrets = {
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
