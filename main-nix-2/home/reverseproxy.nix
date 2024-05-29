{ age, clib }: { lib, config, home, pkgs, inputs, ... }:
let
  NGINX_VERSION = "v0.0.4";
  NGINX_EXPORTER_VERSION = "1.1.0";
  HOMEPAGE_VERSION = "v0.1.4";

  NGINX_CONFIG = "nginx.conf";
  NGINX_CONFIG_DIR = "conf.d";
  WEBSITE_PATH = "/website";
in
{
  imports = [
    ../../shared/usr.nix
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
              runtimeInputs = [ ];
              text = ''
                # add programs
                export PATH="/run/current-system/sw/bin:$PATH"
                
                podman pull docker.io/certbot/certbot
                podman run --rm --name certbot \
                  -e "HETZNER_TOKEN=$(cat '${age.secrets.reverseproxy_hetzner_token.path}')" \
                  -v ${config.data-prefix}/letsencrypt:/etc/letsencrypt \
                  --entrypoint sh \
                  certbot/certbot \
                  -c 'pip install certbot-dns-hetzner; echo "dns_hetzner_api_token = $HETZNER_TOKEN"; echo "dns_hetzner_api_token = $HETZNER_TOKEN" > /hetzner.ini;
                      certbot certonly --email "${config.email}" --agree-tos --non-interactive \
                        --authenticator dns-hetzner --dns-hetzner-credentials /hetzner.ini \
                        --dns-hetzner-propagation-seconds=60 -d *.${config.main-url} -d ${config.main-url}'

                stat -Lc %y "${config.data-prefix}/letsencrypt/live/${config.main-url}/fullchain.pem"
                if [ $(( $(date +%s) - $(stat -Lc %Y "${config.data-prefix}/letsencrypt/live/${config.main-url}/fullchain.pem") )) -lt 120 ]; then 
                  podman exec nginx nginx -s reload && podman logs --tail 20 nginx
                  echo "Reloaded Certificate"
                else 
                  echo "No reload"
                fi'';
            } + /bin/certbot-renewal;
        };
      };
    };
    timers = {
      certbot = {
        Unit = {
          Description = "Service for Certbot Renewal";
        };
        Install = {
          WantedBy = [ "timers.target" ];
        };
        Timer = {
          Unit = "certbot.service";
          OnCalendar = "0/02:00:00";
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
            -p ${toString config.ports.exposed.http}:1080 \
            -p ${toString config.ports.exposed.https}:1443/tcp \
            -p ${toString config.ports.exposed.https}:1443/udp \
            -p ${config.address.private.nginx-exporter}:9113 \
            -p ${config.exporter.port} \
            --network pasta:-a,172.16.0.1

        podman run --name=nginx -d --pod=${config.pod-name} \
            -v ${config.home.homeDirectory}/${NGINX_CONFIG}:/etc/nginx/${NGINX_CONFIG}:ro \
            -v ${config.home.homeDirectory}/${NGINX_CONFIG_DIR}:/etc/nginx/${NGINX_CONFIG_DIR}:ro \
            -v ${config.data-prefix}/letsencrypt:/etc/letsencrypt:ro \
            -v ${config.data-prefix}/website:${WEBSITE_PATH}:ro \
            -v nginx-cache:/var/cache/nginx/:U \
            --restart on-failure:10 \
            docker.io/h3rmt/nginx-http3-br:${NGINX_VERSION}
        
        podman run --name=nginx-exporter -d --pod=${config.pod-name} \
            --restart on-failure:10 \
            docker.io/nginx/nginx-prometheus-exporter:${NGINX_EXPORTER_VERSION} \
            --nginx.scrape-uri=http://localhost:1081/${config.nginx-info-page}

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
        upstream ${config.sites.authentik} {
          server ${config.address.public.authentik};
          keepalive 15;
        }

        upstream ${config.sites.grafana} {
          server ${config.address.public.grafana};
        }

        upstream ${config.sites.prometheus} {
          server ${config.address.public.prometheus};
        }

        upstream ${config.sites.filesharing} {
          server ${config.address.public.filesharing};
        }

        upstream ${config.sites.nextcloud} {
          server ${config.address.public.nextcloud};
        }
      '';
    };

    "${NGINX_CONFIG}" = {
      noLink = true;
      text = ''
        worker_processes 4;
        worker_rlimit_nofile 8192;
        
        error_log /var/log/nginx/error.log notice;
        pid /var/run/nginx.pid;
        
        events {
          worker_connections 2048;
        }
        
        http {
          include /etc/nginx/${NGINX_CONFIG_DIR}/general.conf;
          include /etc/nginx/${NGINX_CONFIG_DIR}/upstreams.conf;
          
          server {
            listen 1081;
            listen [::]:1081;
            server_tokens on;
        
            location /${config.nginx-info-page} {
              stub_status;
              access_log off;
            }
          }
        
          server {
            server_name ${config.main-url};
        
            listen 1080;
            listen [::]:1080;
        
            location / {
              return 301 https://$host$request_uri;
            }
          }
        
          server {
            server_name ${config.main-url};
        
            listen 1443 ssl;
            listen [::]:1443 ssl;
            listen 1443 quic reuseport;
            listen [::]:1443 quic reuseport;
        
            location / {
              root /${WEBSITE_PATH};
            }
          }
        
          server {
            server_name ${config.sites.prometheus}.${config.main-url};
        
            listen 1443 ssl;
            listen [::]:1443 ssl;
            listen 1443 quic;
            listen [::]:1443 quic;
        
            location / {
              proxy_pass http://${config.sites.prometheus};
              include /etc/nginx/${NGINX_CONFIG_DIR}/proxy.conf;
              include /etc/nginx/${NGINX_CONFIG_DIR}/authentik-proxy.conf;
            }
        
            include /etc/nginx/${NGINX_CONFIG_DIR}/authentik-locations.conf;
          }
        
          server {
            server_name ${config.sites.authentik}.${config.main-url};
        
            listen 1443 ssl;
            listen [::]:1443 ssl;
            listen 1443 quic;
            listen [::]:1443 quic;
        
            location / {
              proxy_pass http://${config.sites.authentik};
              include /etc/nginx/${NGINX_CONFIG_DIR}/proxy.conf;
            }
          }
        
          server {
            server_name ${config.sites.grafana}.${config.main-url};
        
            listen 1443 ssl;
            listen [::]:1443 ssl;
            listen 1443 quic;
            listen [::]:1443 quic;
        
            location / {
              proxy_pass http://${config.sites.grafana};
              include /etc/nginx/${NGINX_CONFIG_DIR}/proxy.conf;
            }
          }

          server {
            server_name ${config.sites.nextcloud}.${config.main-url};
          
            listen 1443 ssl;
            listen [::]:1443 ssl;
            listen 1443 quic;
            listen [::]:1443 quic;
            
            client_max_body_size 3000M;
            location / {
              proxy_pass http://${config.sites.nextcloud};
              include /etc/nginx/${NGINX_CONFIG_DIR}/proxy.conf;
            }
          }
                            
          server {
            server_name ${config.sites.filesharing}.${config.main-url};
      
            listen 1443 ssl;
            listen [::]:1443 ssl;
            listen 1443 quic;
            listen [::]:1443 quic;
        
            client_max_body_size 3000M;
            proxy_read_timeout 300;
            proxy_connect_timeout 300;
            proxy_send_timeout 300;
      
            location / {
              proxy_pass http://${config.sites.filesharing};
              include /etc/nginx/${NGINX_CONFIG_DIR}/proxy.conf;
            }
          }
        
        
          #   server {
          #     server_name esp32-timelapse.${config.main-url};
          # 
          #     listen 1443 ssl;
          #     listen [::]:1443 ssl;
          #     listen 1443 quic;
          #     listen [::]:1443 quic;
          # 
          #     location / {
          #       proxy_pass http://esp32-timelapse;
          #       include /etc/nginx/${NGINX_CONFIG_DIR}/proxy.conf;
          #     }
          #   }
        
        
          #   server {
          #     server_name uptest.${config.main-url};
          # 
          #     listen 1443 ssl;
          #     listen [::]:1443 ssl;
          #     listen 1443 quic;
          #     listen [::]:1443 quic;
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
          #     server_name speedtest.${config.main-url};
          # 
          #     listen 1443 ssl;
          #     listen [::]:1443 ssl;
          #     listen 1443 quic;
          #     listen [::]:1443 quic;
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
          proxy_pass              http://${config.sites.authentik}/outpost.goauthentik.io;
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
          return 302 /outpost.goauthentik.io/start?rd=$request_uri;
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
        log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                        '$status $body_bytes_sent "$http_referer" '
                        '"$http_user_agent" "$http_x_forwarded_for"';
        access_log /var/log/nginx/access.log main;
        sendfile   on;
        tcp_nopush on;

        # general
        server_tokens off;

        # http2
        http2 on;

        # http3
        http3 on;
        add_header alt-svc 'h3 = ":443"; ma = 86400' always;
        add_header x-quic 'h3' always;
        ssl_early_data on;
        quic_retry on;
        quic_gso on;
        http3_hq on;

        # https only
        add_header Strict-Transport-Security "max-age=63072000" always;

        # certificates
        ssl_certificate /etc/letsencrypt/live/${config.main-url}/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/${config.main-url}/privkey.pem;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 1h;
        ssl_session_tickets off;
        ssl_buffer_size 4k;
        ssl_protocols TLSv1.3;

        # gzip
        gzip on;
        gzip_proxied expired no-cache no-store private auth;
        gzip_min_length 1000;
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
        brotli_comp_level 4;
        brotli_min_length 1000;
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

