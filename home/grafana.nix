{ lib
, config
, home
, pkgs
, ...
}:
let
  volume-prefix = "${config.vars.volume}/Grafana";
in
{
  imports = [
    ../vars.nix
    ../varsmodule.nix
    ../zsh.nix
  ];
  home.stateVersion = config.vars.nixVersion;

  home. file =
    let
      GRAFANA_VERSION = "10.4.1";
      PROMETHEUS_CONFIG = "./prometheus";
    in
    {
      "compose.yml". text = ''
        services:
          grafana:
            image: docker.io/grafana/grafana-oss:${ GRAFANA_VERSION}
            container_name: grafana
            restart: unless-stopped
            ports:
             - ${ toString config. vars. ports. public. grafana}:3000
            environment:
             - GF_SERVER_ROOT_URL=https://grafana.${ config. vars. main-url}/
             - GF_FEATURE_ENABLE=ssoSettingsApi
            volumes:
             - ${ volume-prefix}/grafana:/var/lib/grafana
             
          prometheus:
            image: prom/prometheus
            container_name: prometheus
            restart: unless-stopped
            command:
              - '--config.file=/etc/prometheus/prometheus.yml'
            ports:
              - ${ toString config. vars. ports. private. prometheus}:9090
            volumes:
              - ${ PROMETHEUS_CONFIG}:/etc/prometheus
              - ${ volume-prefix}/prometheus:/prometheus
      '';

      "${ PROMETHEUS_CONFIG}/prometheus.yml". text = ''
        global:
          scrape_interval: 15s
          scrape_timeout: 10s
          evaluation_interval: 15s
      '';
    };
}
