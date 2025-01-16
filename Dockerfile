FROM docker.io/grafana/promtail:3.0.0
FROM docker.io/prom/node-exporter:v1.7.0
FROM docker.io/nginx/nginx-prometheus-exporter:1.4.1
FROM docker.io/certbot/certbot:v3.1.0
FROM docker.io/grafana/grafana-oss:10.4.1
FROM docker.io/prom/prometheus:v2.51.2
FROM docker.io/grafana/loki:3.0.0
FROM docker.io/library/redis:7.2.4-alpine
FROM docker.io/library/postgres:12-alpine
FROM docker.io/thetorproject/snowflake-proxy:v2.8.1
FROM docker.io/mariadb:11.0
FROM docker.io/nextcloud:29.0.0
FROM ghcr.io/h3rmt/nginx-http3-br:v0.1.2
FROM ghcr.io/h3rmt/filesharing:v1.6.3
FROM ghcr.io/h3rmt/alpine-tor:v0.3.6-exporter
FROM ghcr.io/h3rmt/puppeteer-sma:v0.1.5
FROM ghcr.io/goauthentik/server:2024.10.1
FROM ghcr.io/muety/wakapi:2.11.2
FROM ghcr.io/borgmatic-collective/borgmatic
FROM ghcr.io/h3rmt/borg-prometheus-exporter:v0.1.0