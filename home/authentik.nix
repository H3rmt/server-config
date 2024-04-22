{ lib
, config
, home
, pkgs
, inputs
, ...
}:
let
  volume-prefix = "${config.volume}/Authentik";
  clib = import ../funcs.nix { inherit lib; inherit config; };

  PG_PASS = "XDQCkc0GcPSoNBJdPJK2PbRr2tUfohDeLjXzyJS5";
  POSTGRES_USER = "authentik";
  POSTGRES_DB = "authentik";
  SECRET_KEY = "xtXWgVElTmzYoFL7UoFcnhMJJQ8LkvqVVkSG9SOhxuDGW7dQNf";
  ERROR_REPORTING_ENABLED = "true";

  POSTGRES_VERSION = "12-alpine";
  REDIS_VERSION = "7.2.4-alpine";
  AUTHENTIK_VERSION = "2024.2.2";

in
{
  imports = [
    ../vars.nix
    ../zsh.nix
  ];
  home.stateVersion = config.nixVersion;
  home.sessionVariables.XDG_RUNTIME_DIR = "/run/user/$UID";
  home.file = clib.create-files {
    ".env" = {
      noLink = true;
      text = ''
        AUTHENTIK_SECRET_KEY=${SECRET_KEY}
        AUTHENTIK_ERROR_REPORTING__ENABLED=${ERROR_REPORTING_ENABLED}
      '';
    };

    "compose.yml" = {
      noLink = true;
      text = ''
        services:
          postgresql:
            image: docker.io/library/postgres:${POSTGRES_VERSION}
            container_name: postgresql
            restart: unless-stopped
            healthcheck:
              test: ["CMD-SHELL", "pg_isready -d $${POSTGRES_DB} -U $${POSTGRES_USER}"]
              start_period: 20s
              interval: 30s
              retries: 5
              timeout: 5s
            environment:
              POSTGRES_PASSWORD: ${PG_PASS}
              POSTGRES_USER: ${POSTGRES_USER}
              POSTGRES_DB: ${POSTGRES_DB}
            volumes:
              - ${volume-prefix}/postges:/var/lib/postgresql/data
          
          redis:
            image: docker.io/library/redis:${REDIS_VERSION}
            container_name: redis
            command: --save 60 1 --loglevel warning
            restart: unless-stopped
            healthcheck:
              test: ["CMD-SHELL", "redis-cli ping | grep PONG"]
              start_period: 20s
              interval: 30s
              retries: 5
              timeout: 3s
            volumes:
              - ${volume-prefix}/redis:/data
          
          server:
            image: ghcr.io/goauthentik/server:${AUTHENTIK_VERSION}
            container_name: server
            restart: unless-stopped
            command: server
            environment:
              AUTHENTIK_REDIS__HOST: redis
              AUTHENTIK_POSTGRESQL__HOST: postgresql
              AUTHENTIK_POSTGRESQL__USER: ${POSTGRES_USER}
              AUTHENTIK_POSTGRESQL__NAME: ${POSTGRES_DB}
              AUTHENTIK_POSTGRESQL__PASSWORD: ${PG_PASS}
            user: 0:0
            ports:
              - ${toString config.ports.public.authentik}:9000
            depends_on:
              - postgresql
              - redis
            env_file:
              - .env
            volumes:
              - ${volume-prefix}/media:/media
              - ${volume-prefix}/custom-templates:/templates
    
          worker:
            image: ghcr.io/goauthentik/server:${AUTHENTIK_VERSION}
            container_name: worker
            restart: unless-stopped
            command: worker
            environment:
              AUTHENTIK_REDIS__HOST: redis
              AUTHENTIK_POSTGRESQL__HOST: postgresql
              AUTHENTIK_POSTGRESQL__USER: ${POSTGRES_USER}
              AUTHENTIK_POSTGRESQL__NAME: ${POSTGRES_DB}
              AUTHENTIK_POSTGRESQL__PASSWORD: ${PG_PASS}
            user: 0:0
            depends_on:
              - postgresql
              - redis
            env_file:
              - .env     
            volumes:
              - ${volume-prefix}/media:/media
              - ${volume-prefix}/certs:/certs
              - ${volume-prefix}/custom-templates:/templates
                    
          ${clib.create-podman-exporter "authentik"}
      '';
    };
  };
}
