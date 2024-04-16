{ lib
, config
, home
, pkgs
, ...
}:
let
  volume-prefix = "${config.vars.volume}/Reverseproxy";
in
{
  imports = [
    ../vars.nix
    ../varsmodule.nix
    ../zsh.nix
  ];
  home.stateVersion = config.vars.nixVersion;

  home.file =
    let
      NGINX_VERSION = "v0.0.4";
    in
    {
      "compose.yml".text = ''
        services:
          nginx:
            image: docker.io/h3rmt/nginx-http3-br:${ NGINX_VERSION}
            container_name: nginx
            restart: unless-stopped
            ports:
              - "80:80/tcp"
              - "443:443/tcp"
              - "443:443/udp"
            volumes:
              - ./nginx.conf:/etc/nginx/nginx.conf
              - ./conf.d:/etc/nginx/conf.d/
              - ${volume-prefix}/letsencrypt:/etc/letsencrypt
              - ${volume-prefix}/public:/public
            networks:
              - main
            
        networks:
          main:
            driver: bridge
            name: main
      '';

      "nginx.conf". text = ''
        worker_processes 4;
        worker_rlimit_nofile 8192;
        
        error_log /var/log/nginx/error.log notice;
        pid /var/run/nginx.pid;
        
        events {
          worker_connections 2048;
        }
        
        http {
          include /etc/nginx/conf.d/general.conf;
          include /etc/nginx/conf.d/upstreams.conf;
        
          server {
            server_name ${config.vars.main-url};
        
            listen 80;
            listen [::]:80;
        
            location / {
              return 301 https://$host$request_uri;
            }
          }
        
          server {
            server_name ${config.vars.main-url};
        
            listen 443 ssl;
            listen [::]:443 ssl;
            listen 443 quic reuseport;
            listen [::]:443 quic reuseport;
        
            location / {
              root /public;
            }
          }
        
          server {
            server_name filesharing.${config.vars.main-url};
        
            listen 443 ssl;
            listen [::]:443 ssl;
            listen 443 quic;
            listen [::]:443 quic;
        
            client_max_body_size 3000M;
            proxy_read_timeout 300;
            proxy_connect_timeout 300;
            proxy_send_timeout 300;
        
            location / {
              proxy_pass http://filesharing;
              include /etc/nginx/conf.d/proxy.conf;
            }
          }
        
          server {
            server_name nextcloud.${config.vars.main-url};
        
            listen 443 ssl;
            listen [::]:443 ssl;
            listen 443 quic;
            listen [::]:443 quic;
        
            client_max_body_size 3000M;
        
            location / {
              proxy_pass http://nextcloud;
              include /etc/nginx/conf.d/proxy.conf;
            }
          }
        
          server {
            server_name esp32-timelapse.${config.vars.main-url};
        
            listen 443 ssl;
            listen [::]:443 ssl;
            listen 443 quic;
            listen [::]:443 quic;
        
            location / {
              proxy_pass http://esp32-timelapse;
              include /etc/nginx/conf.d/proxy.conf;
            }
          }
        
          server {
            server_name lasagne-share.${config.vars.main-url};
        
            listen 443 ssl;
            listen [::]:443 ssl;
            listen 443 quic;
            listen [::]:443 quic;
        
            client_max_body_size 3000M;
            proxy_read_timeout 300;
            proxy_connect_timeout 300;
            proxy_send_timeout 300;
        
            location / {
              proxy_pass http://lasagne-share;
              include /etc/nginx/conf.d/proxy.conf;
            }
          }
        
          server {
            server_name uptest.${config.vars.main-url};
        
            listen 443 ssl;
            listen [::]:443 ssl;
            listen 443 quic;
            listen [::]:443 quic;
        
            location / {
              proxy_pass http://uptest;
              include /etc/nginx/conf.d/proxy.conf;
              include /etc/nginx/conf.d/authentik-proxy.conf;
            }
        
            include /etc/nginx/conf.d/authentik-locations.conf;
          }
        
          server {
            server_name speedtest.${config.vars.main-url};
        
            listen 443 ssl;
            listen [::]:443 ssl;
            listen 443 quic;
            listen [::]:443 quic;
        
            client_max_body_size 35M;
        
            location / {
              proxy_pass http://speedtest;
              include /etc/nginx/conf.d/proxy.conf;
              include /etc/nginx/conf.d/authentik-proxy.conf;
            }
        
            include /etc/nginx/conf.d/authentik-locations.conf;
          }
        
          server {
            server_name authentik.${config.vars.main-url};
        
            listen 443 ssl;
            listen [::]:443 ssl;
            listen 443 quic;
            listen [::]:443 quic;
        
            location / {
              proxy_pass http://authentik;
              include /etc/nginx/conf.d/proxy.conf;
            }
          }
        
          server {
            server_name grafana.${config.vars.main-url};
        
            listen 443 ssl;
            listen [::]:443 ssl;
            listen 443 quic;
            listen [::]:443 quic;
        
            location / {
              proxy_pass http://grafana;
              include /etc/nginx/conf.d/proxy.conf;
            }
          }
        }
      '';

      "conf.d/proxy.conf".text = ''
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

      "conf.d/upstreams.conf".text = ''
        upstream authentik {
            server host.containers.internal:${toString config.vars.ports.public.authentik};
            keepalive 15;
        }

        upstream grafana {
            server host.containers.internal:${toString config.vars.ports.public.grafana};
        }
      '';

      "conf.d/authentik-locations.conf".text = ''
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

      "conf.d/authnetik-proxy.conf".text = ''
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

      "conf.d/general.conf".text = ''
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
}
