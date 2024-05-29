{ age, clib }: { lib, config, home, pkgs, inputs, ... }:
let
  NODE_EXPORTER_VERSION = "v1.7.0";
  PROMTAIL_VERSION = "3.0.0";
in
{
  imports = [
    ../../shared/usr.nix
  ];

  home.file = clib.create-files config.home.homeDirectory {
    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${config.pod-name} \
            -p ${config.address.private.node-exporter-2}:9100 \
            -p ${config.exporter.port} \
            --network pasta:-a,172.16.0.1

        podman run --name=node-exporter-2 -d --pod=${config.pod-name} \
            -v '/:/host:ro,rslave' \
            -u 0:0 \
            --restart unless-stopped \
            docker.io/prom/node-exporter:${NODE_EXPORTER_VERSION} \
            --path.rootfs=/host --collector.netdev --collector.processes --collector.ethtool
        
        podman run --name=promtail-2 -d --pod=${config.pod-name} \
            -v ${config.home.homeDirectory}/promtail.yml:/etc/promtail/promtail.yml:ro \
            -v /var/log:/var/log:ro \
            -v /tmp/positions \
            --restart unless-stopped \
            docker.io/grafana/promtail:${PROMTAIL_VERSION} \
            --config.file=/etc/promtail/promtail.yml

        ${config.exporter.run}
      '';
    };

    "down.sh" = {
      executable = true;
      text = ''
        podman stop -t 10 node-exporter-2
        podman stop -t 10 promtail-2
        podman rm node-exporter-2 promtail-2
        ${config.exporter.stop}
        podman pod rm ${config.pod-name}
      '';
    };

    "promtail.yml" = {
      noLink = true;
      text = ''
        positions:
          filename: /tmp/positions.yaml

        clients:
          - url: http://${config.address.public.loki}/loki/api/v1/push

        scrape_configs:
          - job_name: journal
            journal:
              json: false
              max_age: 12h
              path: /var/log/journal
              labels:
                job: systemd-journal
            relabel_configs:
              - source_labels: ["__journal__systemd_unit"]
                target_label: "unit"
              - source_labels: ["__journal__hostname"]
                target_label: host
              - source_labels: ["__journal_priority_keyword"]
                target_label: level
              - source_labels: ["__journal_syslog_identifier"]
                target_label: syslog_identifier
            pipeline_stages:
              - match:
                  selector: '{unit="promtail.service"}'
                  action: drop
'';
    };
  };
}
