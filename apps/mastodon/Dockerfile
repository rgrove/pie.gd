# syntax=docker/dockerfile:1
FROM tootsuite/mastodon:v4.0.2
ARG TARGETARCH
USER root

# Install Caddy
ARG CADDY_VERSION="2.6.2"
RUN \
  TMPFILE=$(mktemp) && \
  wget -O "$TMPFILE" "https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/caddy_${CADDY_VERSION}_linux_${TARGETARCH}.deb" && \
  dpkg -i "$TMPFILE" && \
  rm -f "$TMPFILE"

# Install Hivemind
ARG HIVEMIND_VERSION="1.1.0"
RUN \
  wget -O - "https://github.com/DarthSim/hivemind/releases/download/v${HIVEMIND_VERSION}/hivemind-v${HIVEMIND_VERSION}-linux-${TARGETARCH}.gz" \
    | gunzip --stdout > /usr/bin/hivemind && \
  chmod +x /usr/bin/hivemind

COPY --link apps/mastodon/Caddyfile apps/mastodon/Procfile /opt/mastodon/

# Rails env vars
ENV \
  RAILS_ENV="production" \
  RAILS_SERVE_STATIC_FILES=""

# Mastodon env vars
ENV \
  LOCAL_DOMAIN="pie.gd" \
  REDIS_HOST="pie-gd-redis.internal" \
  REDIS_PORT="6379" \
  S3_ALIAS_HOST="files.pie.gd" \
  S3_BUCKET="pie-gd-uploads" \
  S3_ENABLED="true" \
  S3_ENDPOINT="https://s3.us-west-001.backblazeb2.com" \
  S3_HOSTNAME="s3.us-west-001.backblazeb2.com" \
  S3_PROTOCOL="https" \
  SMTP_AUTHENTICATION="cram_md5" \
  SMTP_FROM_ADDRESS="Mastodon <notifications@pie.gd>" \
  SMTP_PORT="25" \
  SMTP_SERVER="smtp.postmarkapp.com"

USER mastodon
ENTRYPOINT []
