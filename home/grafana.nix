{ lib
, config
, home
, pkgs
, ...
}:
let
  volume-prefix = "${config.volume}/Grafana";
  clib = import ../funcs.nix { inherit lib; inherit config; };

  GRAFANA_VERSION = "10.4.1";
  PROMETHEUS_VERSION = "v2.51.2";
  NODE_EXPORTER_VERSION = "v1.7.0";
  NGINX_EXPORTER_VERSION = "1.1.0";
  PROMETHEUS_CONFIG = "prometheus";
in
{
  imports = [
    ../vars.nix
    ../zsh.nix
  ];
  home.stateVersion = config.nixVersion;
  home.sessionVariables.XDG_RUNTIME_DIR = "/run/user/$UID";

  home.file = clib.create-files {
    "compose.yml" = {
      noLink = true;
      text = ''
        name: "grafana"
        services:
          grafana:
            image: docker.io/grafana/grafana-oss:${GRAFANA_VERSION}
            container_name: grafana
            restart: unless-stopped
            user: "0:0"
            depends_on:
              - prometheus
            ports:
              - ${toString config.ports.public.grafana}:3000
            environment:
              - GF_SERVER_ROOT_URL=https://grafana.${config.main-url}/
              - GF_FEATURE_ENABLE=ssoSettingsApi
            volumes:
              - ${volume-prefix}/grafana:/var/lib/grafana
              - ${volume-prefix}/grafana.ini:/etc/grafana/grafana.ini
              - ${volume-prefix}/grafana-plugins:/var/lib/grafana/plugins
             
          prometheus:
            image: docker.io/prom/prometheus:${PROMETHEUS_VERSION}
            container_name: prometheus
            restart: unless-stopped
            network_mode: bridge
            user: "0:0"
            depends_on:
              - node-exporter
              - nginx-exporter
            command: '--config.file=/etc/prometheus/prometheus.yml --web.enable-lifecycle'
            ports:
              - ${toString config.ports.public.prometheus}:9090
            volumes:
              - ${config.home.homeDirectory}/${PROMETHEUS_CONFIG}:/etc/prometheus
              - ${volume-prefix}/prometheus:/prometheus

          node-exporter:
            image: docker.io/prom/node-exporter:${NODE_EXPORTER_VERSION}
            container_name: node_exporter
            restart: unless-stopped
            user: "0:0"
            command: '--path.rootfs=/host --collector.processes'
            volumes:
              - '/:/host:ro,rslave'
            
          nginx-exporter:
            image: docker.io/nginx/nginx-prometheus-exporter:${NGINX_EXPORTER_VERSION}
            container_name: nginx-exporter
            restart: unless-stopped
            command: '--nginx.scrape-uri=http://host.containers.internal:${toString config.ports.private.nginx-status}/nginx_status --log.level=debug'
      '';
    };

    "${PROMETHEUS_CONFIG}/prometheus.yml" = {
      noLink = true;
      text = ''
        global:
          scrape_interval: 15s
          scrape_timeout: 10s
          evaluation_interval: 15s
          query_log_file: /prometheus/query.log
        scrape_configs:
          - job_name: prometheus
            static_configs:
              - targets: ["prometheus:9090"]
          - job_name: node
            static_configs:
              - targets: ["node-exporter:9100"]
          - job_name: nginx
            static_configs:
              - targets: ["nginx-exporter:9113"]
          - job_name: podman-exporter
            static_configs:
              - targets:
                  [
                    "host.containers.internal:${toString config.ports.private.podman-exporter.reverseproxy}",
                    "host.containers.internal:${toString config.ports.private.podman-exporter.grafana}",
                    "host.containers.internal:${toString config.ports.private.podman-exporter.authentik}",
                    "host.containers.internal:${toString config.ports.private.podman-exporter.snowflake}",
                  ]
      '';
    };
  };
}
