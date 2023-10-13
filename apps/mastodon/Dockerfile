# syntax=docker/dockerfile:1
FROM ghcr.io/mastodon/mastodon:v4.2.1
ARG TARGETARCH
USER root

# Install Nginx Stable
ARG NGINX_VERSION="1.24.0"
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      debian-archive-keyring \
      gettext-base \
      gnupg2 \
      lsb-release && \
    curl https://nginx.org/keys/nginx_signing.key \
      | gpg --dearmor \
      | tee /usr/share/keyrings/nginx-archive-keyring.gpg > /dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/debian `lsb_release -cs` nginx" \
      | tee /etc/apt/sources.list.d/nginx.list && \
    echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" \
      | tee /etc/apt/preferences.d/99nginx && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      nginx=${NGINX_VERSION}-\*

# Make it possible to run Nginx as an unprivileged user
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
  ln -sf /dev/stderr /var/log/nginx/error.log && \
  chown -R mastodon:0 /var/cache/nginx && \
  chmod -R g+w /var/cache/nginx

# Install statsd_exporter
ARG STATSD_EXPORTER_VERSION="0.24.0"
RUN \
  wget -O - "https://github.com/prometheus/statsd_exporter/releases/download/v${STATSD_EXPORTER_VERSION}/statsd_exporter-${STATSD_EXPORTER_VERSION}.linux-${TARGETARCH}.tar.gz" \
    | tar -xz -C /usr/bin --strip-components=1 "statsd_exporter-${STATSD_EXPORTER_VERSION}.linux-${TARGETARCH}/statsd_exporter" && \
  chmod +x /usr/bin/statsd_exporter

# Install Supercronic
ARG SUPERCRONIC_VERSION="0.2.25"
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
  apps/mastodon/crontab \
  apps/mastodon/statsd-mapping.yaml \
  /app/

COPY --link \
  apps/mastodon/nginx.conf \
  /app/nginx.conf.template

COPY --link --chmod=755 \
  apps/mastodon/bin/* \
  /app/bin/

# Rails env vars
ENV RAILS_ENV="production"

# Mastodon/Sidekiq env vars.
#
# These env vars are defined here rather than in fly.toml because this way we
# can spin up an on-demand machine using this Docker image and use it to run
# Mastodon CLI utilities when necessary. The env vars in `fly.toml` are only
# needed when running the actual Mastodon web app.
ENV \
  ES_ENABLED="true" \
  ES_HOST="sea.pie-gd-elasticsearch.internal" \
  ES_PORT="9200" \
  LOCAL_DOMAIN="pie.gd" \
  REDIS_URL="redis://sea.pie-gd-redis.internal:6379/?family=6" \
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

# Replace env var placeholders in nginx.conf.
RUN envsubst '$${LOCAL_DOMAIN}' < /app/nginx.conf.template > /app/nginx.conf && \
  rm /app/nginx.conf.template

ENTRYPOINT ["/app/bin/docker-entrypoint"]
