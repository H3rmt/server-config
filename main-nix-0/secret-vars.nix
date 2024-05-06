{ ... }: {
  age.secrets = {
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
    nextcloud_maria_pass = {
      file = ./secrets/nextcloud/maria_pass.age;
      owner = "nextcloud";
    };
    nextcloud_maria_root_pass = {
      file = ./secrets/nextcloud/maria_root_pass.age;
      owner = "nextcloud";
    };
  };
}
