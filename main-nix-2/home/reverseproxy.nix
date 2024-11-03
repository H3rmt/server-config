{ lib, config, home, pkgs, clib, mainConfig, inputs, ... }:
let
  NGINX_VERSION = "v0.1.2";
  NGINX_EXPORTER_VERSION = "1.1.0";
  HOMEPAGE_VERSION = "v0.1.4";

  NGINX_CONFIG = "nginx.conf";
  NGINX_CONFIG_DIR = "conf.d";
  WEBSITE_PATH = "/website";
in
{
  imports = [
    ../../shared/baseuser.nix
  ];

  home.activation.script = clib.create-folders lib [
    "${config.data-prefix}/letsencrypt/"
    "${config.data-prefix}/website/"
  ];

  exported-services = [ "certbot.timer" "certbot.service" ];

  systemd.user = {
    services = {
      certbot = {
        Unit = {
          Description = "Service for Certbot Renewal";
        };
        Service = {
          ExecStart = pkgs.writeShellApplication
            {
              name = "certbot-renewal";
              runtimeInputs = [ pkgs.coreutils pkgs.podman ];
              text = ''
                start_time=$(date +%s)

                podman pull docker.io/certbot/certbot
                podman run --rm --name certbot \
                  -e "HETZNER_TOKEN=$(cat '${mainConfig.age.secrets.reverseproxy_hetzner_token.path}')" \
                  -v ${config.data-prefix}/letsencrypt:/etc/letsencrypt \
                  --entrypoint sh \
                  certbot/certbot \
                  -c 'pip install certbot-dns-hetzner; echo "dns_hetzner_api_token = $HETZNER_TOKEN"; echo "dns_hetzner_api_token = $HETZNER_TOKEN" > /hetzner.ini;
                      certbot certonly --email "${mainConfig.email}" --agree-tos --non-interactive \
                        --authenticator dns-hetzner --dns-hetzner-credentials /hetzner.ini \
                        --dns-hetzner-propagation-seconds=60 -d *.${mainConfig.main-url} -d ${mainConfig.main-url}'

                stat -Lc %y "${config.data-prefix}/letsencrypt/live/${mainConfig.main-url}/fullchain.pem"
                if [ $(( $(date +%s) - $(stat -Lc %Y "${config.data-prefix}/letsencrypt/live/${mainConfig.main-url}/fullchain.pem") )) -lt 120 ]; then 
                  podman exec nginx nginx -s reload && podman logs --tail 20 nginx
                  echo "Reloaded Certificate"
                else 
                  echo "No reload"
                fi
                
                # Wait for at least 60 seconds before exiting
                while [ $(($(date +%s) - start_time)) -lt 60 ]; do
                    sleep 5  # Sleep for a short duration before checking again
                done
                '';
            } + /bin/certbot-renewal;
        };
      };
    };
    timers = {
      certbot = {
        Unit = {
          Description = "Timer for Certbot Renewal";
        };
        Install = {
          WantedBy = [ "timers.target" ];
        };
        Timer = {
          Unit = "certbot.service";
          OnBootSec = "15min";
          OnCalendar = "*-*-* 2:00:00";
          RandomizedDelaySec = "30m";
          Persistent = true;
        };
      };
    };
  };

  home.file = clib.create-files config.home.homeDirectory {
    "up.sh" = {
      executable = true;
      text = ''
        podman pod create --name=${config.pod-name} --userns=keep-id \
            -p ${toString mainConfig.ports.exposed.http}:1080 \
            -p ${toString mainConfig.ports.exposed.https}:1443/tcp \
            -p ${toString mainConfig.ports.exposed.https}:1443/udp \
            -p ${mainConfig.address.private.nginx-exporter}:9113 \
            -p ${config.exporter.port} \
            --network pasta:-a,172.16.0.1

        podman run --name=nginx -d --pod=${config.pod-name} \
            -v ${config.home.homeDirectory}/${NGINX_CONFIG}:/etc/nginx/${NGINX_CONFIG}:ro \
            -v ${config.home.homeDirectory}/${NGINX_CONFIG_DIR}:/etc/nginx/${NGINX_CONFIG_DIR}:ro \
            -v ${config.data-prefix}/letsencrypt:/etc/letsencrypt:ro \
            -v ${config.data-prefix}/website:${WEBSITE_PATH}:ro \
            -v nginx-cache:/var/cache/nginx/:U \
            -v logs:/var/log/nginx/:U \
            --restart on-failure:20 \
            -u $UID:$GID \
            docker.io/h3rmt/nginx-http3-br:${NGINX_VERSION}
        
        podman run --name=nginx-exporter -d --pod=${config.pod-name} \
            --restart on-failure:10 \
            -u $UID:$GID \
            docker.io/nginx/nginx-prometheus-exporter:${NGINX_EXPORTER_VERSION} \
            --nginx.scrape-uri=http://localhost:1081/${mainConfig.nginx-info-page}

        ${config.exporter.run}
      '';
    };

    "down.sh" = {
      executable = true;
      text = ''
        podman stop -t 10 nginx-exporter
        podman stop -t 10 nginx
        podman rm nginx nginx-exporter
        ${config.exporter.stop}
        podman pod rm ${config.pod-name}
      '';
    };

    "website-version" = {
      onChange = pkgs.writeShellApplication
        {
          name = "update";
          runtimeInputs = [ pkgs.wget pkgs.unzip ];
          text = ''
            echo "https://github.com/H3rmt/h3rmt.github.io/releases/download/$(cat ${config.home.homeDirectory}/website-version)/public.zip";
            wget "https://github.com/H3rmt/h3rmt.github.io/releases/download/$(cat ${config.home.homeDirectory}/website-version)/public.zip" -O temp.zip
            unzip -o temp.zip -d ${config.data-prefix}/website
            rm temp.zip
          '';
        } + /bin/update;
      text = ''
        ${HOMEPAGE_VERSION}
      '';
    };

    "${NGINX_CONFIG_DIR}/upstreams.conf" = {
      noLink = true;
      text = ''
        upstream ${mainConfig.sites.authentik} {
          server ${mainConfig.address.public.authentik};
          keepalive 15;
        }

        upstream ${mainConfig.sites.grafana} {
          server ${mainConfig.address.public.grafana};
        }

        upstream ${mainConfig.sites.prometheus} {
          server ${mainConfig.address.public.prometheus};
        }

        upstream ${mainConfig.sites.filesharing} {
          server ${mainConfig.address.public.filesharing};
        }

        upstream ${mainConfig.sites.nextcloud} {
          server ${mainConfig.address.public.nextcloud};
        }

        upstream ${mainConfig.sites.wakapi} {
          server ${mainConfig.address.public.wakapi};
        }
      '';
    };

    "${NGINX_CONFIG}" = {
      noLink = true;
      text = ''
        worker_processes 4;
        worker_rlimit_nofile 8192;
        
        error_log /var/log/nginx/error.log notice;
        pid /tmp/nginx.pid;
        
        events {
          worker_connections 2048;
        }
        
        http {
          include /etc/nginx/${NGINX_CONFIG_DIR}/general.conf;
          include /etc/nginx/${NGINX_CONFIG_DIR}/upstreams.conf;
          
          server {
            listen 1081;
            server_tokens on;
        
            location /${mainConfig.nginx-info-page} {
              stub_status;
              access_log off;
            }
          }
        
          server {
            server_name ${mainConfig.main-url};
        
            listen 1080;
            listen [::0]:1080;
        
            location / {
              return 301 https://$host$request_uri;
            }
          }
        
          server {
            server_name ${mainConfig.main-url};
            add_header alt-svc 'h3=":443"; ma=2592000';
        
            listen 1443 quic reuseport;
            listen [::0]:1443 quic reuseport;
            listen 1443 ssl;
            listen [::0]:1443 ssl;
        
            location / {
              root /${WEBSITE_PATH};
            }
          }
        
          server {
            server_name ${mainConfig.sites.prometheus}.${mainConfig.main-url};
            add_header alt-svc 'h3=":443"; ma=2592000';

            listen 1443 quic;
            listen [::0]:1443 quic;
            listen 1443 ssl;
            listen [::0]:1443 ssl;
        
            location / {
              proxy_pass http://${mainConfig.sites.prometheus};
              include /etc/nginx/${NGINX_CONFIG_DIR}/proxy.conf;
              include /etc/nginx/${NGINX_CONFIG_DIR}/authentik-proxy.conf;
            }
        
            include /etc/nginx/${NGINX_CONFIG_DIR}/authentik-locations.conf;
          }
        
          server {
            server_name ${mainConfig.sites.authentik}.${mainConfig.main-url};

            listen 1443 ssl;
            listen [::0]:1443 ssl;
        
            location / {
              proxy_pass http://${mainConfig.sites.authentik};
              include /etc/nginx/${NGINX_CONFIG_DIR}/proxy.conf;
            }
          }
        
          server {
            server_name ${mainConfig.sites.grafana}.${mainConfig.main-url};
            add_header alt-svc 'h3=":443"; ma=2592000';
        
            listen 1443 quic;
            listen [::0]:1443 quic;
            listen 1443 ssl;
            listen [::0]:1443 ssl;
        
            location / {
              proxy_pass http://${mainConfig.sites.grafana};
              include /etc/nginx/${NGINX_CONFIG_DIR}/proxy.conf;
            }
          }

          server {
            server_name ${mainConfig.sites.nextcloud}.${mainConfig.main-url};

            listen 1443 ssl;
            listen [::0]:1443 ssl;
            
            client_max_body_size 3000M;
            location / {
              proxy_pass http://${mainConfig.sites.nextcloud};
              include /etc/nginx/${NGINX_CONFIG_DIR}/proxy.conf;
            }
          }
                            
          server {
            server_name ${mainConfig.sites.filesharing}.${mainConfig.main-url};
            add_header alt-svc 'h3=":443"; ma=2592000';
      
            listen 1443 quic;
            listen [::0]:1443 quic;
            listen 1443 ssl;
            listen [::0]:1443 ssl;
        
            client_max_body_size 3000M;
            proxy_read_timeout 300;
            proxy_connect_timeout 300;
            proxy_send_timeout 300;
      
            location / {
              proxy_pass http://${mainConfig.sites.filesharing};
              include /etc/nginx/${NGINX_CONFIG_DIR}/proxy.conf;
            }
          }
        
          server {
            server_name ${mainConfig.sites.wakapi}.${mainConfig.main-url};
            add_header alt-svc 'h3=":443"; ma=2592000';
      
            listen 1443 quic;
            listen [::0]:1443 quic;
            listen 1443 ssl;
            listen [::0]:1443 ssl;
        
            location / {
              proxy_pass http://${mainConfig.sites.wakapi};
              include /etc/nginx/${NGINX_CONFIG_DIR}/proxy.conf;
              include /etc/nginx/${NGINX_CONFIG_DIR}/authentik-proxy.conf;

              auth_request_set $wakapi_username $upstream_http_x_wakapi_username;
              proxy_set_header X-wakapi-username $wakapi_username;
            }
        
            include /etc/nginx/${NGINX_CONFIG_DIR}/authentik-locations.conf;
          }

          #   server {
          #     server_name esp32-timelapse.${mainConfig.main-url};
          # 
          #     listen 1443 ssl;
          #     listen [::0]:1443 ssl;
          #     listen 1443 quic;
          #     listen [::0]:1443 quic;
          # 
          #     location / {
          #       proxy_pass http://esp32-timelapse;
          #       include /etc/nginx/${NGINX_CONFIG_DIR}/proxy.conf;
          #     }
          #   }
        
        
          #   server {
          #     server_name uptest.${mainConfig.main-url};
          # 
          #     listen 1443 ssl;
          #     listen [::0]:1443 ssl;
          #     listen 1443 quic;
          #     listen [::0]:1443 quic;
          # 
          #     location / {
          #       proxy_pass http://uptest;
          #       include /etc/nginx/${NGINX_CONFIG_DIR}/proxy.conf;
          #       include /etc/nginx/${NGINX_CONFIG_DIR}/authentik-proxy.conf;
          #     }
          # 
          #     include /etc/nginx/${NGINX_CONFIG_DIR}/authentik-locations.conf;
          #   }
        
          #   server {
          #     server_name speedtest.${mainConfig.main-url};
          # 
          #     listen 1443 ssl;
          #     listen [::0]:1443 ssl;
          #     listen 1443 quic;
          #     listen [::0]:1443 quic;
          # 
          #     client_max_body_size 35M;
          # 
          #     location / {
          #       proxy_pass http://speedtest;
          #       include /etc/nginx/${NGINX_CONFIG_DIR}/proxy.conf;
          #       include /etc/nginx/${NGINX_CONFIG_DIR}/authentik-proxy.conf;
          #     }
          # 
          #     include /etc/nginx/${NGINX_CONFIG_DIR}/authentik-locations.conf;
          #   }
        }
      '';
    };
    "${NGINX_CONFIG_DIR}/proxy.conf" = {
      noLink = true;
      text = ''
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade_keepalive;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
      '';
    };

    "${NGINX_CONFIG_DIR}/authentik-locations.conf" = {
      noLink = true;
      text = ''
        location /outpost.goauthentik.io {
          proxy_pass              http://${mainConfig.sites.authentik}/outpost.goauthentik.io;
          proxy_set_header        Host $host;
          proxy_set_header        X-Original-URL $scheme://$http_host$request_uri;
          add_header              Set-Cookie $auth_cookie;
          auth_request_set        $auth_cookie $upstream_http_set_cookie;
          proxy_pass_request_body off;
          proxy_set_header        Content-Length "";
        }

        # Special location for when the /auth endpoint returns a 401,
        # redirect to the /start URL which initiates SSO
        location @goauthentik_proxy_signin {
          internal;
          add_header Set-Cookie $auth_cookie;
          return 302 $scheme://$server_name/outpost.goauthentik.io/start?rd=$request_uri;
        }
      '';
    };

    "${NGINX_CONFIG_DIR}/authentik-proxy.conf" = {
      noLink = true;
      text = ''
        auth_request     /outpost.goauthentik.io/auth/nginx;
        error_page       401 = @goauthentik_proxy_signin;
        auth_request_set $auth_cookie $upstream_http_set_cookie;
        add_header       Set-Cookie $auth_cookie;

        # translate headers from the outposts back to the actual upstream
        auth_request_set $authentik_username $upstream_http_x_authentik_username;
        auth_request_set $authentik_groups $upstream_http_x_authentik_groups;
        auth_request_set $authentik_email $upstream_http_x_authentik_email;
        auth_request_set $authentik_name $upstream_http_x_authentik_name;
        auth_request_set $authentik_uid $upstream_http_x_authentik_uid;

        proxy_set_header X-authentik-username $authentik_username;
        proxy_set_header X-authentik-groups $authentik_groups;
        proxy_set_header X-authentik-email $authentik_email;
        proxy_set_header X-authentik-name $authentik_name;
        proxy_set_header X-authentik-uid $authentik_uid;
      '';
    };

    "${NGINX_CONFIG_DIR}/general.conf" = {
      noLink = true;
      text = ''
        map $http_upgrade $connection_upgrade_keepalive {
          default upgrade;
          "" "";
        }

        include /etc/nginx/mime.types;
        default_type application/octet-stream;
        log_format main '[$time_iso8601] $server_name $status $request_method $server_protocol $content_length $uri';
        access_log /var/log/nginx/access.log main; 
        # sendfile   on;
        # tcp_nopush on;

        # general
        server_tokens off;
        client_max_body_size 50M;
        proxy_max_temp_file_size 0;

        # http2
        http2 on;

        # http3
        http3 on;
        ssl_early_data on;
        # quic_retry on;
        # quic_gso on;

        # https only
        add_header Strict-Transport-Security "max-age=63072000" always;

        # certificates
        ssl_certificate /etc/letsencrypt/live/${mainConfig.main-url}/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/${mainConfig.main-url}/privkey.pem;
        ssl_session_cache shared:SSL:10m;
        # ssl_session_timeout 1h;
        # ssl_session_tickets off;
        ssl_buffer_size 4k;
        ssl_protocols TLSv1.3;

        # gzip
        gzip on;
        gzip_proxied any;
        gzip_min_length 100;
        gzip_types
          application/x-javascript
          application/javascript
          application/json
          application/xml
          image/svg+xml
          text/javascript
          text/css
          text/plain;

        # brotli
        brotli on;
        brotli_comp_level 8;
        brotli_min_length 100;
        brotli_types
          application/x-javascript
          application/javascript
          application/json
          application/xml
          image/svg+xml
          text/javascript
          text/css
          text/plain;
      '';
    };
  };
}

