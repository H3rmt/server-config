{ lib, config, ... }: {
  create-podman-exporter = name:
    ''
      podman-exporter:
          image: quay.io/navidys/prometheus-podman-exporter:${toString config.podman-exporter-version}
          container_name: podman-exporter-${name}
          restart: unless-stopped
          user: "0:0"
          command: '--collector.enable-all'
          ports:
            - ${toString config.ports.private.podman-exporter.${name}}:9882
          environment:
            - CONTAINER_HOST=unix:///run/podman/podman.sock
          volumes:
            - $XDG_RUNTIME_DIR/podman/podman.sock:/run/podman/podman.sock  
    '';

  create-files = files: (lib.mapAttrs (name: { text, noLink ? false, onChange ? "" }:
    let
      home = config.home.homeDirectory;
    in
    {
      inherit text;
      target = if noLink then ".links/${name}" else "${name}";
      onChange =
        if noLink then ''
          rm -f ${home}/${name}
          install -D ${home}/.links/${name} ${home}/${name}
          chmod 555 ${home}/${name}
          ${onChange}
        ''
        else onChange;
    })) files;
}
