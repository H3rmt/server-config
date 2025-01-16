{ lib, config, home, pkgs, clib, mainConfig, inputs, ... }:
let
  PG_PASS = ''$(cat "${mainConfig.age.secrets.authentik_pg_pass.path}")'';
  SECRET_KEY = ''$(cat "${mainConfig.age.secrets.authentik_key.path}")'';
  POSTGRES_USER = "authentik";
  POSTGRES_DB = "authentik";
  ERROR_REPORTING_ENABLED = "true";
in
{
  imports = [
    ../../shared/baseuser.nix
  ];

  home.activation.script = clib.create-folders lib [
    "${config.data-prefix}/postges/"
    "${config.data-prefix}/redis/"
    "${config.data-prefix}/media/"
    "${config.data-prefix}/templates/"
    "${config.data-prefix}/certs/"
  ];

  home.file = clib.create-files config.home.homeDirectory {
    "compare.sh" = {
      executable = true;
      text = ''
        echo ${config.compare.start}
        echo docker.io/library/postgres:${mainConfig.image-versions."docker.io/library/postgres"}
        echo docker.io/library/redis:${mainConfig.image-versions."docker.io/library/redis"}
        echo ghcr.io/goauthentik/server:${mainConfig.image-versions."ghcr.io/goauthentik/server"}
        echo ${config.compare.end}
      '';
    };
    
    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${config.pod-name} --userns=keep-id \
            -p ${mainConfig.address.public.authentik}:9000 \
            -p ${config.exporter.port} \
            --network pasta:-a,172.16.0.1
            
        podman run --name=postgresql -d --pod=${config.pod-name} \
            -e POSTGRES_PASSWORD=${PG_PASS} \
            -e POSTGRES_USER=${POSTGRES_USER} \
            -e POSTGRES_DB=${POSTGRES_DB} \
            -v ${config.data-prefix}/postges:/var/lib/postgresql/data:U \
            --restart on-failure:10 \
            -u $UID:$GID \
            --healthcheck-command "/bin/sh -c 'pg_isready -d ${POSTGRES_DB} -U ${POSTGRES_USER}'" \
            --healthcheck-interval 30s \
            --healthcheck-timeout 5s \
            --healthcheck-start-period 20s \
            --healthcheck-retries 5 \
            docker.io/library/postgres:${mainConfig.image-versions."docker.io/library/postgres"}

        podman run --name=redis -d --pod=${config.pod-name} \
            -v ${config.data-prefix}/redis:/data:U \
            --restart on-failure:10 \
            -u $UID:$GID \
            --healthcheck-command "/bin/sh -c 'redis-cli ping | grep PONG'" \
            --healthcheck-interval 30s \
            --healthcheck-timeout 3s \
            --healthcheck-start-period 20s \
            --healthcheck-retries 5 \
            docker.io/library/redis:${mainConfig.image-versions."docker.io/library/redis"} \
            --save 60 1 --loglevel warning

        podman run --name=server -d --pod=${config.pod-name} \
            -e AUTHENTIK_SECRET_KEY=${SECRET_KEY} \
            -e AUTHENTIK_ERROR_REPORTING__ENABLED=${ERROR_REPORTING_ENABLED} \
            -e AUTHENTIK_REDIS__HOST=redis \
            -e AUTHENTIK_POSTGRESQL__HOST=postgresql \
            -e AUTHENTIK_POSTGRESQL__USER=${POSTGRES_USER} \
            -e AUTHENTIK_POSTGRESQL__NAME=${POSTGRES_DB} \
            -e AUTHENTIK_POSTGRESQL__PASSWORD=${PG_PASS} \
            -v ${config.data-prefix}/media:/media:U \
            -v ${config.data-prefix}/templates:/templates:U \
            --restart on-failure:10 \
            -u $UID:$GID \
            ghcr.io/goauthentik/server:${mainConfig.image-versions."ghcr.io/goauthentik/server"} \
            server
            
        podman run --name=worker -d --pod=${config.pod-name} \
            -e AUTHENTIK_SECRET_KEY=${SECRET_KEY} \
            -e AUTHENTIK_ERROR_REPORTING__ENABLED=${ERROR_REPORTING_ENABLED} \
            -e AUTHENTIK_REDIS__HOST=redis \
            -e AUTHENTIK_POSTGRESQL__HOST=postgresql \
            -e AUTHENTIK_POSTGRESQL__USER=${POSTGRES_USER} \
            -e AUTHENTIK_POSTGRESQL__NAME=${POSTGRES_DB} \
            -e AUTHENTIK_POSTGRESQL__PASSWORD=${PG_PASS} \
            -v ${config.data-prefix}/media:/media:U \
            -v ${config.data-prefix}/templates:/templates:U \
            -v ${config.data-prefix}/certs:/certs:U \
            --restart on-failure:10 \
            -u $UID:$GID \
            ghcr.io/goauthentik/server:${mainConfig.image-versions."ghcr.io/goauthentik/server"} \
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
