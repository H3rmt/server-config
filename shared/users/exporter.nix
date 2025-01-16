{ config, mainConfig, clib, ... }:
let
  NODE_EXPORTER_VERSION = "v1.7.0";
  PROMTAIL_VERSION = "3.0.0";
in
{
  imports = [
    ../baseuser.nix
  ];

  home.file = clib.create-files config.home.homeDirectory {
    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${config.pod-name} --userns=keep-id \
            -p ${mainConfig.address.private.node-exporter."${mainConfig.exporter-user-prefix}-${mainConfig.networking.hostName}"}:9100 \
            -p ${config.exporter.port} \
            --network pasta:-a,172.16.0.1

        podman run --name=node-exporter-${mainConfig.networking.hostName} -d --pod=${config.pod-name} \
            -v '/:/host:ro,rslave' \
            --restart on-failure:10 \
            -u $UID:$GID \
            docker.io/prom/node-exporter:${mainConfig.image-versions."docker.io/prom/node-exporter"} \
            --path.rootfs=/host
        
        podman run --name=promtail-${mainConfig.networking.hostName} -d --pod=${config.pod-name} \
            -v ${config.home.homeDirectory}/promtail.yml:/etc/promtail/promtail.yml:ro \
            -v /var/log:/var/log:ro \
            -v positions:/tmp/positions:U \
            --group-add=keep-groups \
            --restart on-failure:10 \
            -u $UID:$GID \
            docker.io/grafana/promtail:${mainConfig.image-versions."docker.io/grafana/promtail"} \
            --config.file=/etc/promtail/promtail.yml

        ${config.exporter.run}
      '';
    };

    "down.sh" = {
      executable = true;
      text = ''
        podman stop -t 10 node-exporter-${mainConfig.networking.hostName}
        podman stop -t 10 promtail-${mainConfig.networking.hostName}
        podman rm node-exporter-${mainConfig.networking.hostName} node-exporter-${mainConfig.networking.hostName}
        ${config.exporter.stop}
        podman pod rm ${config.pod-name}
      '';
    };

    "promtail.yml" = {
      noLink = true;
      text = ''
        server:
          http_listen_port: 0
          grpc_listen_port: 0

        positions:
          filename: /tmp/positions.yaml

        clients:
          - url: http://${mainConfig.address.public.loki}/loki/api/v1/push

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
