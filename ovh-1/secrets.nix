{ ... }:
{
  age.secrets.wireguard_private.rekeyFile = ./secrets/wireguard_private.age;
  age.secrets.wireguard_private.group = "systemd-network";
  age.secrets.wireguard_private.mode = "640";

  age.secrets.hetzner-external-dns.rekeyFile = ./secrets/hetzner_external_dns.age;
  age.secrets.hetzner-cert-manager.rekeyFile = ./secrets/hetzner_cert_manager.age;
  age.secrets.traefik-auth-secret-longhorn.rekeyFile = ./secrets/traefik-auth-secret-longhorn.age;
}
