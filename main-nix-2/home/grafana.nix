{ age, clib, mconfig }: { lib, config, home, pkgs, inputs, ... }:
let
  data-prefix = "${config.home.homeDirectory}/data";

  PODNAME = "grafana_pod";
  GRAFANA_VERSION = "10.4.1";
  PROMETHEUS_VERSION = "v2.51.2";

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

  home.activation.script = clib.create-folders lib [
    "${data-prefix}/grafana/"
    "${data-prefix}/prometheus/"
  ];

  home.file = clib.create-files config.home.homeDirectory {
    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${PODNAME} \
            -p ${mconfig.main-nix-2-private-ip}:${toString mconfig.ports.public.grafana}:3000 \
            -p ${mconfig.main-nix-2-private-ip}:${toString mconfig.ports.public.prometheus}:9090 \
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

        ${exporter.run}
      '';
    };

    "down.sh" = {
      executable = true;
      text = ''
        podman stop -t 10 grafana
        podman stop -t 10 prometheus
        podman rm grafana prometheus
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
        root_url = "https://${mconfig.sites.grafana}.${mconfig.main-url}/"
        
        [feature_toggles]
        ssoSettingsApi = true
        
        [auth]
        signout_redirect_url = https://${mconfig.sites.authentik}.${mconfig.main-url}/application/o/grafana/end-session/
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
        auth_url = https://${mconfig.sites.authentik}.${mconfig.main-url}/application/o/authorize/
        token_url = https://${mconfig.sites.authentik}.${mconfig.main-url}/application/o/token/
        api_url = https://${mconfig.sites.authentik}.${mconfig.main-url}/application/o/userinfo/
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
                    "${mconfig.main-nix-1-private-ip}:${toString mconfig.ports.private.node-exporter-1}",
                    "${mconfig.main-nix-2-private-ip}:${toString mconfig.ports.private.node-exporter-2}",
                  ]
          - job_name: nginx
            static_configs:
              - targets:
                  [
                    "${mconfig.main-nix-2-private-ip}:${toString mconfig.ports.private.nginx-exporter}",
                  ]
          - job_name: tor
            static_configs:
              - targets:
                  [
                    "${mconfig.main-nix-2-private-ip}:${toString mconfig.ports.private.tor-exporter}",
                  ]
          - job_name: systemd
            static_configs:
              - targets:
                  [
                    "${mconfig.main-nix-2-private-ip}:${toString mconfig.ports.private.systemd-exporter}",
                  ]
          - job_name: podman-exporter
            static_configs:
              - targets:
                  [
                    "${mconfig.main-nix-2-private-ip}:${toString mconfig.ports.private.podman-exporter.reverseproxy}",
                    "${mconfig.main-nix-2-private-ip}:${toString mconfig.ports.private.podman-exporter.grafana}",
                    "${mconfig.main-nix-2-private-ip}:${toString mconfig.ports.private.podman-exporter.authentik}",
                    "${mconfig.main-nix-2-private-ip}:${toString mconfig.ports.private.podman-exporter.node-exporter-2}",
                    "${mconfig.main-nix-2-private-ip}:${toString mconfig.ports.private.podman-exporter.tor}",
                    "${mconfig.main-nix-1-private-ip}:${toString mconfig.ports.private.podman-exporter.filesharing}",
                    "${mconfig.main-nix-1-private-ip}:${toString mconfig.ports.private.podman-exporter.nextcloud}",
                    "${mconfig.main-nix-1-private-ip}:${toString mconfig.ports.private.podman-exporter.node-exporter-1}",
                  ]
      '';
    };
  };
}
