{ lib, config, ... }: {
  create-podman-exporter = name: podname: {
    run = ''
      podman run --name=podman-exporter-${name} -d --pod=${podname} \
          -e CONTAINER_HOST=unix:///run/podman/podman.sock \
          -v $XDG_RUNTIME_DIR/podman/podman.sock:/run/podman/podman.sock \
          -u 0:0 \
          --restart unless-stopped \
          quay.io/navidys/prometheus-podman-exporter:${toString config.podman-exporter-version} \
          --collector.enable-all'';

    stop = ''
      podman stop -t 10 podman-exporter-${name}
      podman rm podman-exporter-${name}'';

    port = ''
      ${toString config.ports.private.podman-exporter.${name}}:9882'';
  };

  create-files = home: files: (lib.mapAttrs (name: { text, noLink ? false, onChange ? "", executable ? false }: {
    inherit text;
    inherit executable;
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

  create-folders = folders: lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p ${toString folders}
  ''
}
