{ lib, config, home, pkgs, clib, mainConfig, inputs, ... }:
let
  GRAFANA_VERSION = "10.4.1";
  PROMETHEUS_VERSION = "v2.51.2";
  LOKI_VERSION = "3.0.0";

  GRAFANA_CONFIG = "grafana";
  PROMETHEUS_CONFIG = "prometheus";
  LOKI_CONFIG = "loki";
in
{
  imports = [
    ../../shared/baseuser.nix
  ];

  home.activation.script = clib.create-folders lib [
    "${config.data-prefix}/grafana/"
    "${config.data-prefix}/prometheus/"
    "${config.data-prefix}/loki/"
  ];

  home.file = clib.create-files config.home.homeDirectory {
    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${config.pod-name} --userns=keep-id \
            -p ${mainConfig.address.public.grafana}:3000 \
            -p ${mainConfig.address.public.loki}:3100 \
            -p ${mainConfig.address.public.prometheus}:9090 \
            -p ${config.exporter.port} \
            --network pasta:-a,172.16.0.1

        podman run --name=grafana -d --pod=${config.pod-name} \
            -v ${config.home.homeDirectory}/${GRAFANA_CONFIG}:/etc/grafana:ro \
            -v ${config.data-prefix}/grafana:/var/lib/grafana:U \
            --restart on-failure:10 \
            -u $UID:$GID \
            docker.io/grafana/grafana-oss:${GRAFANA_VERSION}

        podman run --name=prometheus -d --pod=${config.pod-name} \
            -v ${config.home.homeDirectory}/${PROMETHEUS_CONFIG}:/etc/prometheus:ro \
            -v ${config.data-prefix}/prometheus:/prometheus:U \
            --restart on-failure:10 \
            -u $UID:$GID \
            docker.io/prom/prometheus:${PROMETHEUS_VERSION} \
            --config.file=/etc/prometheus/prometheus.yml --web.enable-lifecycle --storage.tsdb.retention.time=5y

        podman run --name=loki -d --pod=${config.pod-name} \
            -v ${config.home.homeDirectory}/${LOKI_CONFIG}:/etc/loki:ro \
            -v ${config.data-prefix}/loki:/var/loki:U \
            --restart on-failure:10 \
            -u $UID:$GID \
            docker.io/grafana/loki:${LOKI_VERSION} \
            -config.file=/etc/loki/config.yml

        ${config.exporter.run}
      '';
    };

    "down.sh" = {
      executable = true;
      text = ''
        podman stop -t 10 grafana
        podman stop -t 10 prometheus
        podman stop -t 10 loki
        podman rm grafana prometheus loki
        ${config.exporter.stop}
        podman pod rm ${config.pod-name}
      '';
    };

    "${GRAFANA_CONFIG}/grafana.ini" = {
      noLink = true;
      onChange = ''
        grafana_client_secret=$(cat "${mainConfig.age.secrets.grafana_client_secret.path}")
        grafana_client_key=$(cat "${mainConfig.age.secrets.grafana_client_key.path}")
        configFile="${config.home.homeDirectory}/${GRAFANA_CONFIG}/grafana.ini"
        sed -e "s/@grafana_client_secret@/$grafana_client_secret/g" -e "s/@grafana_client_key@/$grafana_client_key/g" -i "$configFile"
      '';
      text = ''
        [server]
        root_url = "https://${mainConfig.sites.grafana}.${mainConfig.main-url}/"
        
        [feature_toggles]
        ssoSettingsApi = true
        
        [auth]
        signout_redirect_url = https://${mainConfig.sites.authentik}.${mainConfig.main-url}/application/o/grafana/end-session/
        disable_login_form = true
        
        [auth.generic_oauth]
        allow_sign_up = true
        auto_login = true
        skip_org_role_sync = true
        name = authentik
        enabled = true
        client_id = @grafana_client_key@
        client_secret = @grafana_client_secret@
        scopes = openid email profile
        auth_url = https://${mainConfig.sites.authentik}.${mainConfig.main-url}/application/o/authorize/
        token_url = https://${mainConfig.sites.authentik}.${mainConfig.main-url}/application/o/token/
        api_url = https://${mainConfig.sites.authentik}.${mainConfig.main-url}/application/o/userinfo/

        [dataproxy]
        # This enables data proxy logging
        logging = false
      '';
    };

    "${PROMETHEUS_CONFIG}/prometheus.yml" = {
      noLink = true;
      onChange = ''
        grafana_wakapi_metrics_key=$(cat "${mainConfig.age.secrets.grafana_wakapi_metrics_key.path}" | base64)
        configFile="${config.home.homeDirectory}/${PROMETHEUS_CONFIG}/prometheus.yml"
        sed -e "s/@grafana_wakapi_metrics_key@/$grafana_wakapi_metrics_key/g" -i "$configFile"
      '';
      text = ''
        global:
          scrape_interval: 15s
          evaluation_interval: 15s
          scrape_timeout: 5s
          query_log_file: /prometheus/query.log
        scrape_configs:
          - job_name: prometheus
            static_configs:
              - targets: ["prometheus:9090"]
          - job_name: snowflake
            scrape_interval: 2m
            static_configs:
              - targets:
                  [
                    "${mainConfig.address.private.snowflake-exporter-1}",
                    "${mainConfig.address.private.snowflake-exporter-2}",
                  ]
            metrics_path: /internal/metrics
          - job_name: node
            static_configs:
              - targets:
                  [
                    "${mainConfig.address.private.node-exporter."${mainConfig.exporter-user-prefix}-${mainConfig.server.main-1.name}"}",
                    "${mainConfig.address.private.node-exporter."${mainConfig.exporter-user-prefix}-${mainConfig.server.main-2.name}"}",
                    "${mainConfig.address.private.node-exporter."${mainConfig.exporter-user-prefix}-${mainConfig.server.raspi-1.name}"}",
                  ]
          - job_name: nginx
            scrape_interval: 20s
            static_configs:
              - targets:
                  [
                    "${mainConfig.address.private.nginx-exporter}",
                  ]
          - job_name: wakapi
            scrape_interval: 5m
            metrics_path: '/api/metrics'
            bearer_token: '@grafana_wakapi_metrics_key@'
            static_configs:
              - targets:
                  [
                    "${mainConfig.address.public.wakapi}",
                  ]
          - job_name: tor
            static_configs:
              - targets:
                  [
                    "${mainConfig.address.private.tor-exporter}",
                    "${mainConfig.address.private.tor-exporter-bridge}",
                  ]
          - job_name: wireguard
            scrape_interval: 10s
            static_configs:
              - targets:
                  [
                    "${mainConfig.address.private.wireguard."wireguard-exporter-${mainConfig.server.main-1.name}"}",
                    "${mainConfig.address.private.wireguard."wireguard-exporter-${mainConfig.server.main-2.name}"}",
                    "${mainConfig.address.private.wireguard."wireguard-exporter-${mainConfig.server.raspi-1.name}"}",
                  ]
          - job_name: systemd
            scrape_interval: 10s
            static_configs:
              - targets:
                  [
                    "${mainConfig.address.private.systemd-exporter.reverseproxy}",
                  ]
                labels:
                  user: 'reverseproxy'
              - targets:
                  [
                    "${mainConfig.address.private.systemd-exporter."${mainConfig.server.main-1.name}"}",
                  ]
                labels:
                  user: 'root-${mainConfig.server.main-1.name}'
              - targets:
                  [
                    "${mainConfig.address.private.systemd-exporter."${mainConfig.server.main-2.name}"}",
                  ]
                labels:
                  user: 'root-${mainConfig.server.main-2.name}'
              - targets:
                  [
                    "${mainConfig.address.private.systemd-exporter."${mainConfig.server.raspi-1.name}"}",
                  ]
                labels:
                  user: 'root-${mainConfig.server.raspi-1.name}'
          - job_name: podman-exporter
            scrape_interval: 30s
            static_configs:
              - targets:
                  [
                    "${mainConfig.address.private.podman-exporter.reverseproxy}",
                    "${mainConfig.address.private.podman-exporter.grafana}",
                    "${mainConfig.address.private.podman-exporter.authentik}",
                    "${mainConfig.address.private.podman-exporter."${mainConfig.exporter-user-prefix}-${mainConfig.server.main-1.name}"}",
                    "${mainConfig.address.private.podman-exporter.tor}",
                    "${mainConfig.address.private.podman-exporter.filesharing}",
                    "${mainConfig.address.private.podman-exporter.nextcloud}",
                    "${mainConfig.address.private.podman-exporter."${mainConfig.exporter-user-prefix}-${mainConfig.server.main-2.name}"}",
                    "${mainConfig.address.private.podman-exporter.wakapi}",
                    "${mainConfig.address.private.podman-exporter.bridge}",
                    "${mainConfig.address.private.podman-exporter.snowflake}",
                    "${mainConfig.address.private.podman-exporter."${mainConfig.exporter-user-prefix}-${mainConfig.server.raspi-1.name}"}",
                  ]
      '';
    };

    "${LOKI_CONFIG}/config.yml" = {
      noLink = true;
      text = ''
        auth_enabled: false

        server:
          http_listen_port: 3100
          log_level: warn

        common:
          ring:
            instance_addr: 127.0.0.1
            kvstore:
              store: inmemory
          replication_factor: 1

        schema_config:
          configs:
          - from: 2020-05-15
            store: tsdb
            object_store: filesystem
            schema: v13
            index:
              prefix: index_
              period: 24h

        storage_config:
          filesystem:
            directory: /var/loki/chunks
          tsdb_shipper:
            active_index_directory: /var/loki/tsdb-index
            cache_location: /var/loki/tsdb-cache
        
        compactor:
          retention_enabled: true
          compaction_interval: 30m
          retention_delete_delay: 2h
          retention_delete_worker_count: 150
          working_directory: /var/loki/compactor
          delete_request_store: filesystem

        limits_config:
          retention_period: 336h  # 14 days in hours

        ingester:
          wal:
            dir: /var/loki/wal
      '';
    };
  };
}


                  