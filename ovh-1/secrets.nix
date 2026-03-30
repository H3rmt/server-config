{ ... }:
{
  age.secrets.wireguard_private.rekeyFile = ./secrets/wireguard_private.age;
  age.secrets.wireguard_private.group = "systemd-network";
  age.secrets.wireguard_private.mode = "640";

  age.secrets.hetzner-external-dns.rekeyFile = ./secrets/hetzner_external_dns.age;
  age.secrets.hetzner-cert-manager.rekeyFile = ./secrets/hetzner_cert_manager.age;
  age.secrets.traefik-auth-secret-longhorn.rekeyFile = ./secrets/traefik-auth-secret-longhorn.age;
  age.secrets.garage-rpc.rekeyFile = ./secrets/garage_rpc.age;
  age.secrets.garage-webui.rekeyFile = ./secrets/garage_webui.age;
  age.secrets.grafana-admin.rekeyFile = ./secrets/grafana-admin.age;
  age.secrets.traefik-auth-secret-alerts.rekeyFile = ./secrets/traefik-auth-secret-alerts.age;
}
