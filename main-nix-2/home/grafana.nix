{ age, clib, mconfig }: { lib, config, home, pkgs, inputs, ... }:
let
  data-prefix = "${config.home.homeDirectory}/data";

  PODNAME = "grafana_pod";
  GRAFANA_VERSION = "10.4.1";
  PROMETHEUS_VERSION = "v2.51.2";
  NODE_EXPORTER_VERSION = "v1.7.0";
  NGINX_EXPORTER_VERSION = "1.1.0";

  GRAFANA_CONFIG = "grafana";
  PROMETHEUS_CONFIG = "prometheus";

  exporter = clib.create-podman-exporter "grafana" "${PODNAME}";
in
{
  imports = [
    ../../shared/usr.nix
  ];
  home.stateVersion = mconfig.nixVersion;
  home.sessionVariables.XDG_RUNTIME_DIR = "/run/user/$UID";

  home.file = clib.create-files config.home.homeDirectory {
    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${PODNAME} \
            -p ${toString config.ports.public.grafana}:3000 \
            -p ${toString config.ports.public.prometheus}:9090 \
            -p ${mconfig.main-nix-2-private-ip}:${exporter.port} \
            --network pasta:-a,172.16.0.1

        podman run --name=grafana -d --pod=${PODNAME} \
            -v ${config.home.homeDirectory}/${GRAFANA_CONFIG}:/etc/grafana:ro \
            -v ${data-prefix}/grafana:/var/lib/grafana \
            -u 0:0 \
            --restart unless-stopped \
            docker.io/grafana/grafana-oss:${GRAFANA_VERSION}

        podman run --name=prometheus -d --pod=${PODNAME} \
            -v ${config.home.homeDirectory}/${PROMETHEUS_CONFIG}:/etc/prometheus:ro \
            -v ${data-prefix}/prometheus:/prometheus \
            -u 0:0 \
            --restart unless-stopped \
            docker.io/prom/prometheus:${PROMETHEUS_VERSION} \
            --config.file=/etc/prometheus/prometheus.yml --web.enable-lifecycle

        podman run --name=node-exporter -d --pod=${PODNAME} \
            -v '/:/host:ro,rslave' \
            -u 0:0 \
            --restart unless-stopped \
            docker.io/prom/node-exporter:${NODE_EXPORTER_VERSION} \
            --path.rootfs=/host --collector.processes
        
        podman run --name=nginx-exporter -d --pod=${PODNAME} \
            --restart unless-stopped \
            docker.io/nginx/nginx-prometheus-exporter:${NGINX_EXPORTER_VERSION} \
            --nginx.scrape-uri=http://${mconfig.main-nix-2-private-ip}:${toString config.ports.private.nginx-status}/${config.nginx-info-page}

        ${exporter.run}
      '';
    };

    "down.sh" = {
      executable = true;
      text = ''
        podman stop -t 10 grafana
        podman stop -t 10 node-exporter
        podman stop -t 10 nginx-exporter
        podman stop -t 10 prometheus
        podman rm grafana node-exporter nginx-exporter prometheus
        ${exporter.stop}
        podman pod rm ${PODNAME}
      '';
    };

    "${GRAFANA_CONFIG}/grafana.ini" = {
      noLink = true;
      onChange = ''
        grafana_client_secret=$(cat "${age.secrets.grafana_client_secret.path}")
        grafana_client_key=$(cat "${age.secrets.grafana_client_key.path}")
        configFile="${config.home.homeDirectory}/${GRAFANA_CONFIG}/grafana.ini"
        sed -e "s/@grafana_client_secret@/$grafana_client_secret/g" -e "s/@grafana_client_key@/$grafana_client_key/g" -i "$configFile"
      '';
      text = ''
        [server]
        root_url = "https://${config.sites.grafana}.${config.main-url}/"
        
        [feature_toggles]
        ssoSettingsApi = true
        
        [auth]
        signout_redirect_url = https://${config.sites.authentik}.${config.main-url}/application/o/grafana/end-session/
        oauth_auto_login = true
        
        [auth.generic_oauth]
        name = authentik
        enabled = true
        client_id = @grafana_client_key@
        client_secret = @grafana_client_secret@
        scopes = openid email profile
        auth_url = https://${config.sites.authentik}.${config.main-url}/application/o/authorize/
        token_url = https://${config.sites.authentik}.${config.main-url}/application/o/token/
        api_url = https://${config.sites.authentik}.${config.main-url}/application/o/userinfo/
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
                    "${mconfig.main-nix-2-private-ip}:${toString config.ports.private.podman-exporter.reverseproxy}",
                    "${mconfig.main-nix-2-private-ip}:${toString config.ports.private.podman-exporter.grafana}",
                    "${mconfig.main-nix-2-private-ip}:${toString config.ports.private.podman-exporter.authentik}",
                    "${mconfig.main-nix-1-private-ip}:${toString config.ports.private.podman-exporter.filesharing}",
                    # "host.containers.internal:${toString config.ports.private.podman-exporter.snowflake}",
                    # "host.containers.internal:${toString config.ports.private.podman-exporter.nextcloud}",
                  ]
      '';
    };
  };
}