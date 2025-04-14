{ config, ...} : {
  age.rekey = {
    masterIdentities = [ {
      pubkey = "age1r2zyl6zznw44lzurjpvt9mhzmnsg70494x6ga7vlw24rvuq5hpwq09r6p7";
      identity = ./secrets/privkey.age;
    }];
    storageMode = "local";
    localStorageDir = ./. + "/secrets/${config.networking.hostName}";
  };

  age.secrets.k3s.rekeyFile = ./secrets/k3s-token.age;
  age.secrets.root-pass.rekeyFile = ./secrets/root-pass.age;
}