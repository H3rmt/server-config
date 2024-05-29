{ age, clib }: { lib, config, home, pkgs, inputs, ... }:
let
  GRAFANA_VERSION = "10.4.1";
  PROMETHEUS_VERSION = "v2.51.2";

  GRAFANA_CONFIG = "grafana";
  PROMETHEUS_CONFIG = "prometheus";
in
{
  imports = [
    ../../shared/usr.nix
  ];

  home.activation.script = clib.create-folders lib [
    "${config.data-prefix}/grafana/"
    "${config.data-prefix}/prometheus/"
  ];

  home.file = clib.create-files config.home.homeDirectory {
    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${config.pod-name} \
            -p ${config.address.public.grafana}:3000 \
            -p ${config.address.public.prometheus}:9090 \
            -p ${config.exporter.port} \
            --network pasta:-a,172.16.0.1

        podman run --name=grafana -d --pod=${config.pod-name} \
            -v ${config.home.homeDirectory}/${GRAFANA_CONFIG}:/etc/grafana:ro \
            -v ${config.data-prefix}/grafana:/var/lib/grafana \
            -u 0:0 \
            --restart unless-stopped \
            docker.io/grafana/grafana-oss:${GRAFANA_VERSION}

        podman run --name=prometheus -d --pod=${config.pod-name} \
            -v ${config.home.homeDirectory}/${PROMETHEUS_CONFIG}:/etc/prometheus:ro \
            -v ${config.data-prefix}/prometheus:/prometheus \
            -u 0:0 \
            --restart unless-stopped \
            docker.io/prom/prometheus:${PROMETHEUS_VERSION} \
            --config.file=/etc/prometheus/prometheus.yml --web.enable-lifecycle

        ${config.exporter.run}
      '';
    };

    "down.sh" = {
      executable = true;
      text = ''
        podman stop -t 10 grafana
        podman stop -t 10 prometheus
        podman rm grafana prometheus
        ${config.exporter.stop}
        podman pod rm ${config.pod-name}
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
          evaluation_interval: 15s
          scrape_timeout: 5s
          query_log_file: /prometheus/query.log
        scrape_configs:
          - job_name: prometheus
            static_configs:
              - targets: ["prometheus:9090"]
          - job_name: node
            static_configs:
              - targets:
                  [
                    "${config.address.private.node-exporter-1}",
                    "${config.address.private.node-exporter-2}",
                  ]
          - job_name: nginx
            static_configs:
              - targets:
                  [
                    "${config.address.private.nginx-exporter}",
                  ]
          - job_name: tor
            static_configs:
              - targets:
                  [
                    "${config.address.private.tor-exporter}",
                  ]
          - job_name: systemd
            static_configs:
              - targets:
                  [
                    "${config.address.private.systemd-exporter.reverseproxy}",
                  ]
                labels:
                  user: 'reverseproxy'
          - job_name: podman-exporter
            static_configs:
              - targets:
                  [
                    "${toString config.address.private.podman-exporter.reverseproxy}",
                    "${toString config.address.private.podman-exporter.grafana}",
                    "${toString config.address.private.podman-exporter.authentik}",
                    "${toString config.address.private.podman-exporter.node-exporter-2}",
                    "${toString config.address.private.podman-exporter.tor}",
                    "${toString config.address.private.podman-exporter.filesharing}",
                    "${toString config.address.private.podman-exporter.nextcloud}",
                    "${toString config.address.private.podman-exporter.node-exporter-1}",
                  ]
      '';
    };
  };
}


                  