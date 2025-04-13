{ config, ...} : {
  age.rekey = {
    masterIdentities = [ {
      pubkey = "age1r2zyl6zznw44lzurjpvt9mhzmnsg70494x6ga7vlw24rvuq5hpwq09r6p7";
      identity = ./privkey.age;
    }];
    storageMode = "local";
    localStorageDir = ./. + "/secrets/${config.networking.hostName}";
  };

  age.secrets.k3s.rekeyFile = ./k3s-token.age;
}