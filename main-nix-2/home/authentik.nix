{ age, clib, mconfig }: { lib, config, home, pkgs, inputs, ... }:
let
  data-prefix = "${config.home.homeDirectory}/${mconfig.data-dir}";

  PODNAME = "authentik_pod";
  POSTGRES_VERSION = "12-alpine";
  REDIS_VERSION = "7.2.4-alpine";
  AUTHENTIK_VERSION = "2024.2.2";

  PG_PASS = ''$(cat "${age.secrets.authentik_pg_pass.path}")'';
  SECRET_KEY = ''$(cat "${age.secrets.authentik_key.path}")'';
  POSTGRES_USER = "authentik";
  POSTGRES_DB = "authentik";
  ERROR_REPORTING_ENABLED = "true";

  exporter = clib.create-podman-exporter "authentik" "${PODNAME}";
in
{
  imports = [
    ../vars.nix
    ../zsh.nix
  ];
  home.stateVersion = config.nixVersion;
  home.sessionVariables.XDG_RUNTIME_DIR = "/run/user/$UID";

  home.file = clib.create-files config.home.homeDirectory {
   "${data-prefix}/postges/.keep" = {
      text = "";
    };
    "${data-prefix}/redis/.keep" = {
      text = "";
    };
    "${data-prefix}/media/.keep" = {
      text = "";
    };
    "${data-prefix}/templates/.keep" = {
      text = "";
    };
    "${data-prefix}/certs/.keep" = {
      text = "";
    };

    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${PODNAME} \
            -p ${toString config.ports.public.authentik}:9000 \
            -p ${exporter.port} \
            --network pasta:-a,172.16.0.1
            
        podman run --name=postgresql -d --pod=${PODNAME} \
            -e POSTGRES_PASSWORD=${PG_PASS} \
            -e POSTGRES_USER=${POSTGRES_USER} \
            -e POSTGRES_DB=${POSTGRES_DB} \
            -v ${data-prefix}/postges:/var/lib/postgresql/data \
            --restart unless-stopped \
            --healthcheck-command "/bin/sh -c 'pg_isready -d $${POSTGRES_DB} -U $${POSTGRES_USER}'" \
            --healthcheck-interval 30s \
            --healthcheck-timeout 5s \
            --healthcheck-start-period 20s \
            --healthcheck-retries 5 \
            docker.io/library/postgres:${POSTGRES_VERSION}

        podman run --name=redis -d --pod=${PODNAME} \
            -v ${data-prefix}/redis:/data \
            --restart unless-stopped \
            --healthcheck-command "/bin/sh -c 'redis-cli ping | grep PONG'" \
            --healthcheck-interval 30s \
            --healthcheck-timeout 3s \
            --healthcheck-start-period 20s \
            --healthcheck-retries 5 \
            docker.io/library/redis:${REDIS_VERSION} \
            --save 60 1 --loglevel warning

        podman run --name=server -d --pod=${PODNAME} \
            -e AUTHENTIK_SECRET_KEY=${SECRET_KEY} \
            -e AUTHENTIK_ERROR_REPORTING__ENABLED=${ERROR_REPORTING_ENABLED} \
            -e AUTHENTIK_REDIS__HOST=redis \
            -e AUTHENTIK_POSTGRESQL__HOST=postgresql \
            -e AUTHENTIK_POSTGRESQL__USER=${POSTGRES_USER} \
            -e AUTHENTIK_POSTGRESQL__NAME=${POSTGRES_DB} \
            -e AUTHENTIK_POSTGRESQL__PASSWORD=${PG_PASS} \
            -v ${data-prefix}/media:/media \
            -v ${data-prefix}/templates:/templates \
            --restart unless-stopped \
            ghcr.io/goauthentik/server:${AUTHENTIK_VERSION} \
            server
            
        podman run --name=worker -d --pod=${PODNAME} \
            -e AUTHENTIK_SECRET_KEY=${SECRET_KEY} \
            -e AUTHENTIK_ERROR_REPORTING__ENABLED=${ERROR_REPORTING_ENABLED} \
            -e AUTHENTIK_REDIS__HOST=redis \
            -e AUTHENTIK_POSTGRESQL__HOST=postgresql \
            -e AUTHENTIK_POSTGRESQL__USER=${POSTGRES_USER} \
            -e AUTHENTIK_POSTGRESQL__NAME=${POSTGRES_DB} \
            -e AUTHENTIK_POSTGRESQL__PASSWORD=${PG_PASS} \
            -v ${volume-prefix}/media:/media \
            -v ${volume-prefix}/templates:/templates \
            -v ${volume-prefix}/certs:/certs \
            --restart unless-stopped \
            ghcr.io/goauthentik/server:${AUTHENTIK_VERSION} \
            worker
        
        ${exporter.run}
      '';
    };

    "down.sh" = {
      executable = true;
      text = ''
        podman stop -t 10 worker
        podman stop -t 10 server
        podman stop -t 10 redis
        podman stop -t 10 postgresql
        podman rm worker server redis postgresql
        ${exporter.stop}
        podman pod rm ${PODNAME}
      '';
    };
  };
}
