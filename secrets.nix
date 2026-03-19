{ config, ... }:
{
  age.rekey = {
    masterIdentities = [
      {
        pubkey = "age1r2zyl6zznw44lzurjpvt9mhzmnsg70494x6ga7vlw24rvuq5hpwq09r6p7";
        identity = ./secrets/privkey.age;
      }
    ];
    storageMode = "local";
    localStorageDir = ./. + "/secrets/rekey/${config.networking.hostName}";
  };

  age.secrets.k3s.rekeyFile = ./secrets/k3s_token.age;
  age.secrets.root-pass.rekeyFile = ./secrets/root_pass.age;
  age.secrets.hetzner-external-dns.rekeyFile = ./secrets/hetzner_external_dns.age;
  age.secrets.hetzner-cert-manager.rekeyFile = ./secrets/hetzner_cert_manager.age;
  age.secrets.traefik-auth-secret-longhorn.rekeyFile = ./secrets/traefik-auth-secret-longhorn.age;
}
