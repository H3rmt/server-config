{ config, ... }: {
  age.secrets = {
    "borg_pass_${config.hostnames.main-1}" = {
      file = ./secrets/borg/main-nix-1.age;
      owner = "${config.backup-user-prefix}-${config.networking.hostName}";
    };
    "borg_pass_${config.hostnames.main-2}" = {
      file = ./secrets/borg/main-nix-2.age;
      owner = "${config.backup-user-prefix}-${config.networking.hostName}";
    };
    "borg_pass_${config.hostnames.raspi-1}" = {
      file = ./secrets/borg/raspi-1.age;
      owner = "${config.backup-user-prefix}-${config.networking.hostName}";
    };
    root_pass = {
      file = ./secrets/root_pass.age;
      owner = "root";
    };
    wireguard_private = {
      file = ./secrets/wireguard_private.age;
      owner = "root";
      group = "systemd-network";
      mode = "640";
    };
    reverseproxy_hetzner_token = {
      file = ./secrets/reverseproxy/hetzner_token.age;
      owner = "reverseproxy";
    };
    authentik_pg_pass = {
      file = ./secrets/authentik/pg_pass.age;
      owner = "authentik";
    };
    authentik_key = {
      file = ./secrets/authentik/authentik_key.age;
      owner = "authentik";
    };
    grafana_client_secret = {
      file = ./secrets/grafana/client_secret.age;
      owner = "grafana";
    };
    grafana_client_key = {
      file = ./secrets/grafana/client_key.age;
      owner = "grafana";
    };
    grafana_wakapi_metrics_key = {
      file = ./secrets/grafana/wakapi_metrics_key.age;
      owner = "grafana";
    };
    wakapi_salt = {
      file = ./secrets/wakapi/salt.age;
      owner = "wakapi";
    };
  };
}
