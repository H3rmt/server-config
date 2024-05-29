{ age, clib }: { lib, config, home, pkgs, inputs, ... }:
let
  POSTGRES_VERSION = "12-alpine";
  REDIS_VERSION = "7.2.4-alpine";
  AUTHENTIK_VERSION = "2024.2.2";

  PG_PASS = ''$(cat "${age.secrets.authentik_pg_pass.path}")'';
  SECRET_KEY = ''$(cat "${age.secrets.authentik_key.path}")'';
  POSTGRES_USER = "authentik";
  POSTGRES_DB = "authentik";
  ERROR_REPORTING_ENABLED = "true";
in
{
  imports = [
    ../../shared/usr.nix
  ];

  home.activation.script = clib.create-folders lib [
    "${config.data-prefix}/postges/"
    "${config.data-prefix}/redis/"
    "${config.data-prefix}/media/"
    "${config.data-prefix}/templates/"
    "${config.data-prefix}/certs/"
  ];

  home.file = clib.create-files config.home.homeDirectory {
    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${config.pod-name} \
            -p ${config.address.public.authentik}:9000 \
            -p ${config.exporter.port} \
            --network pasta:-a,172.16.0.1
            
        podman run --name=postgresql -d --pod=${config.pod-name} \
            -e POSTGRES_PASSWORD=${PG_PASS} \
            -e POSTGRES_USER=${POSTGRES_USER} \
            -e POSTGRES_DB=${POSTGRES_DB} \
            -v ${config.data-prefix}/postges:/var/lib/postgresql/data \
            --restart unless-stopped \
            --healthcheck-command "/bin/sh -c 'pg_isready -d $${POSTGRES_DB} -U $${POSTGRES_USER}'" \
            --healthcheck-interval 30s \
            --healthcheck-timeout 5s \
            --healthcheck-start-period 20s \
            --healthcheck-retries 5 \
            docker.io/library/postgres:${POSTGRES_VERSION}

        podman run --name=redis -d --pod=${config.pod-name} \
            -v ${config.data-prefix}/redis:/data \
            --restart unless-stopped \
            --healthcheck-command "/bin/sh -c 'redis-cli ping | grep PONG'" \
            --healthcheck-interval 30s \
            --healthcheck-timeout 3s \
            --healthcheck-start-period 20s \
            --healthcheck-retries 5 \
            docker.io/library/redis:${REDIS_VERSION} \
            --save 60 1 --loglevel warning

        podman run --name=server -d --pod=${config.pod-name} \
            -e AUTHENTIK_SECRET_KEY=${SECRET_KEY} \
            -e AUTHENTIK_ERROR_REPORTING__ENABLED=${ERROR_REPORTING_ENABLED} \
            -e AUTHENTIK_REDIS__HOST=redis \
            -e AUTHENTIK_POSTGRESQL__HOST=postgresql \
            -e AUTHENTIK_POSTGRESQL__USER=${POSTGRES_USER} \
            -e AUTHENTIK_POSTGRESQL__NAME=${POSTGRES_DB} \
            -e AUTHENTIK_POSTGRESQL__PASSWORD=${PG_PASS} \
            -v ${config.data-prefix}/media:/media \
            -v ${config.data-prefix}/templates:/templates \
            --restart unless-stopped \
            -u 0:0 \
            ghcr.io/goauthentik/server:${AUTHENTIK_VERSION} \
            server
            
        podman run --name=worker -d --pod=${config.pod-name} \
            -e AUTHENTIK_SECRET_KEY=${SECRET_KEY} \
            -e AUTHENTIK_ERROR_REPORTING__ENABLED=${ERROR_REPORTING_ENABLED} \
            -e AUTHENTIK_REDIS__HOST=redis \
            -e AUTHENTIK_POSTGRESQL__HOST=postgresql \
            -e AUTHENTIK_POSTGRESQL__USER=${POSTGRES_USER} \
            -e AUTHENTIK_POSTGRESQL__NAME=${POSTGRES_DB} \
            -e AUTHENTIK_POSTGRESQL__PASSWORD=${PG_PASS} \
            -v ${config.data-prefix}/media:/media \
            -v ${config.data-prefix}/templates:/templates \
            -v ${config.data-prefix}/certs:/certs \
            --restart unless-stopped \
            -u 0:0 \
            ghcr.io/goauthentik/server:${AUTHENTIK_VERSION} \
            worker
        
        ${config.exporter.run}
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
        ${config.exporter.stop}
        podman pod rm ${config.pod-name}
      '';
    };
  };
}
