# syntax=docker/dockerfile:1
FROM ghcr.io/mastodon/mastodon:v4.1.2
ARG TARGETARCH
USER root

# Install statsd_exporter
ARG STATSD_EXPORTER_VERSION="0.23.1"
RUN \
  wget -O - "https://github.com/prometheus/statsd_exporter/releases/download/v${STATSD_EXPORTER_VERSION}/statsd_exporter-${STATSD_EXPORTER_VERSION}.linux-${TARGETARCH}.tar.gz" \
    | tar -xz -C /usr/bin --strip-components=1 "statsd_exporter-${STATSD_EXPORTER_VERSION}.linux-${TARGETARCH}/statsd_exporter" && \
  chmod +x /usr/bin/statsd_exporter

# Install Caddy
ARG CADDY_VERSION="2.6.4"
RUN \
  TMPFILE=$(mktemp) && \
  wget -O "$TMPFILE" "https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/caddy_${CADDY_VERSION}_linux_${TARGETARCH}.deb" && \
  dpkg -i "$TMPFILE" && \
  rm -f "$TMPFILE"

# Install Supercronic
ARG SUPERCRONIC_VERSION="0.2.23"
RUN \
  wget -O /usr/bin/supercronic "https://github.com/aptible/supercronic/releases/download/v${SUPERCRONIC_VERSION}/supercronic-linux-${TARGETARCH}" && \
  chmod +x /usr/bin/supercronic

# Install Hivemind
ARG HIVEMIND_VERSION="1.1.0"
RUN \
  wget -O - "https://github.com/DarthSim/hivemind/releases/download/v${HIVEMIND_VERSION}/hivemind-v${HIVEMIND_VERSION}-linux-${TARGETARCH}.gz" \
    | gunzip --stdout > /usr/bin/hivemind && \
  chmod +x /usr/bin/hivemind

COPY --link \
  apps/mastodon/Procfile.mastodon \
  apps/mastodon/Procfile.sidekiq \
  /opt/mastodon/

COPY --link \
  apps/mastodon/Caddyfile \
  apps/mastodon/crontab \
  apps/mastodon/statsd-mapping.yaml \
  /app/

COPY --link --chmod=755 \
  apps/mastodon/bin/* \
  /app/bin/

# Rails env vars
ENV RAILS_ENV="production"

# Mastodon/Sidekiq env vars
ENV \
  LOCAL_DOMAIN="pie.gd" \
  REDIS_URL="redis://sea.pie-gd-redis.internal:6379" \
  S3_ALIAS_HOST="files.pie.gd" \
  S3_BUCKET="pie-gd-uploads" \
  S3_ENABLED="true" \
  S3_ENDPOINT="https://s3.us-west-001.backblazeb2.com" \
  S3_HOSTNAME="s3.us-west-001.backblazeb2.com" \
  S3_OPEN_TIMEOUT="20" \
  S3_PROTOCOL="https" \
  S3_READ_TIMEOUT="20" \
  SMTP_AUTHENTICATION="cram_md5" \
  SMTP_FROM_ADDRESS="Mastodon <notifications@pie.gd>" \
  SMTP_PORT="25" \
  SMTP_SERVER="smtp.postmarkapp.com"

USER mastodon
ENTRYPOINT []
