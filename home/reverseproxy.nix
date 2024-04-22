{ lib
, config
, home
, pkgs
, ...
}:
let
  volume-prefix = "${config.volume}/Reverseproxy";
  clib = import ../funcs.nix { inherit lib; inherit config; };

  NGINX_VERSION = "v0.0.4";
  HOMEPAGE_VERSION = "v0.1.3";
  NGINX_CONFIG = "nginx.conf";
  NGINX_CONFIG_DIR = "conf.d";
in
{
  imports = [
    ../vars.nix
    ../zsh.nix
  ];
  home.stateVersion = config.nixVersion;
  home.sessionVariables.XDG_RUNTIME_DIR = "/run/user/$UID";

  home.file = clib.create-files {
    "update" =
      let
        update = pkgs.writeShellApplication {
          name = "update";
          runtimeInputs = [ pkgs.wget pkgs.unzip ];
          text = ''
            echo "https://github.com/H3rmt/h3rmt.github.io/releases/download/$(cat ${config.home.homeDirectory}/update)/public.zip";
            wget "https://github.com/H3rmt/h3rmt.github.io/releases/download/$(cat ${config.home.homeDirectory}/update)/public.zip" -O temp.zip
            unzip -o temp.zip -d ${volume-prefix}
            rm temp.zip
          '';
        };
      in
      {
        onChange = ''${update}/bin/update'';
        text = ''
          ${HOMEPAGE_VERSION}
        '';
      };

    "compose.yml" = {
      noLink = true;
      text = ''
        services:
          nginx:
            image: docker.io/h3rmt/nginx-http3-br:${NGINX_VERSION}
            container_name: nginx
            restart: unless-stopped
            ports:
              - "${toString config.ports.public.http}:80"
              - "${toString config.ports.private.nginx-status}:81"
              - "${toString config.ports.public.https}:443/tcp"
              - "${toString config.ports.public.https}:443/udp"
            volumes:
              - ${config.home.homeDirectory}/${NGINX_CONFIG}:/etc/nginx/${NGINX_CONFIG}
              - ${config.home.homeDirectory}/${NGINX_CONFIG_DIR}:/etc/nginx/${NGINX_CONFIG_DIR}
              - ${volume-prefix}/letsencrypt:/etc/letsencrypt
              - ${volume-prefix}/public:/public

          ${clib.create-podman-exporter "nginx"}
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
            listen 81;
            listen [::]:81;
          	
            location /nginx_status {
              stub_status;
              access_log off;
            }
          }
          
          server {
            server_name ${config.main-url};
          
            listen 80;
            listen [::]:80;

            location / {
              add_header Server $remote_addr;
              return 301 https://$host$request_uri;
            }
          }
          
          server {
            server_name ${config.main-url};
          
            listen 443 ssl;
            listen [::]:443 ssl;
            listen 443 quic reuseport;
            listen [::]:443 quic reuseport;
                            
            location / {
              root /public;
            }
          }

          server {
            server_name prometheus.${config.main-url};
          
            listen 443 ssl;
            listen [::]:443 ssl;
            listen 443 quic;
            listen [::]:443 quic;
          
            location / {
              proxy_pass http://prometheus;
              include /etc/nginx/${NGINX_CONFIG_DIR}/proxy.conf;
              include /etc/nginx/${NGINX_CONFIG_DIR}/authentik-proxy.conf;
            }
          
            include /etc/nginx/${NGINX_CONFIG_DIR}/authentik-locations.conf;
          }
          
        #   server {
        #     server_name filesharing.${config.main-url};
        # 
        #     listen 443 ssl;
        #     listen [::]:443 ssl;
        #     listen 443 quic;
        #     listen [::]:443 quic;
        # 
        #     client_max_body_size 3000M;
        #     proxy_read_timeout 300;
        #     proxy_connect_timeout 300;
        #     proxy_send_timeout 300;
        # 
        #     location / {
        #       proxy_pass http://filesharing;
        #       include /etc/nginx/${NGINX_CONFIG_DIR}/proxy.conf;
        #     }
        #   }
          
        #   server {
        #     server_name nextcloud.${config.main-url};
        # 
        #     listen 443 ssl;
        #     listen [::]:443 ssl;
        #     listen 443 quic;
        #     listen [::]:443 quic;
        # 
        #     client_max_body_size 3000M;
        # 
        #     location / {
        #       proxy_pass http://nextcloud;
        #       include /etc/nginx/${NGINX_CONFIG_DIR}/proxy.conf;
        #     }
        #   }
          
        #   server {
        #     server_name esp32-timelapse.${config.main-url};
        # 
        #     listen 443 ssl;
        #     listen [::]:443 ssl;
        #     listen 443 quic;
        #     listen [::]:443 quic;
        # 
        #     location / {
        #       proxy_pass http://esp32-timelapse;
        #       include /etc/nginx/${NGINX_CONFIG_DIR}/proxy.conf;
        #     }
        #   }
          
        #   server {
        #     server_name lasagne-share.${config.main-url};
        # 
        #     listen 443 ssl;
        #     listen [::]:443 ssl;
        #     listen 443 quic;
        #     listen [::]:443 quic;
        # 
        #     client_max_body_size 3000M;
        #     proxy_read_timeout 300;
        #     proxy_connect_timeout 300;
        #     proxy_send_timeout 300;
        # 
        #     location / {
        #       proxy_pass http://lasagne-share;
        #       include /etc/nginx/${NGINX_CONFIG_DIR}/proxy.conf;
        #     }
        #   }
          
        #   server {
        #     server_name uptest.${config.main-url};
        # 
        #     listen 443 ssl;
        #     listen [::]:443 ssl;
        #     listen 443 quic;
        #     listen [::]:443 quic;
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
        #     listen 443 ssl;
        #     listen [::]:443 ssl;
        #     listen 443 quic;
        #     listen [::]:443 quic;
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
          
          server {
            server_name authentik.${config.main-url};
          
            listen 443 ssl;
            listen [::]:443 ssl;
            listen 443 quic;
            listen [::]:443 quic;
          
            location / {
              proxy_pass http://authentik;
              include /etc/nginx/${NGINX_CONFIG_DIR}/proxy.conf;
            }
          }
          
          server {
            server_name grafana.${config.main-url};
          
            listen 443 ssl;
            listen [::]:443 ssl;
            listen 443 quic;
            listen [::]:443 quic;
          
            location / {
              proxy_pass http://grafana;
              include /etc/nginx/${NGINX_CONFIG_DIR}/proxy.conf;
            }
          }
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

    "${NGINX_CONFIG_DIR}/upstreams.conf" = {
      noLink = true;
      text = ''
        upstream authentik {
          server host.containers.internal:${toString config.ports.public.authentik};
          keepalive 15;
        }
  
        upstream grafana {
          server host.containers.internal:${toString config.ports.public.grafana};
        }

        upstream prometheus {
          server host.containers.internal:${toString config.ports.public.prometheus};
        }
      '';
    };

    "${NGINX_CONFIG_DIR}/authentik-locations.conf" = {
      noLink = true;
      text = ''
        location /outpost.goauthentik.io {
          proxy_pass              http://authentik/outpost.goauthentik.io;
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
        add_header alt-svc 'h3=":443"; ma=86400' always;
        add_header x-quic 'h3' always;
        ssl_early_data on;
        quic_retry on;
        quic_gso on;
        http3_hq on;
        
        # https only
        add_header Strict-Transport-Security "max-age=63072000" always;
        
        # certificates
        ssl_certificate /etc/letsencrypt/live/h3rmt.zip/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/h3rmt.zip/privkey.pem;
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
