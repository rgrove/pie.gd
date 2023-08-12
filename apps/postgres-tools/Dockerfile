# syntax=docker/dockerfile:1
FROM postgres:15.3
USER root
WORKDIR /opt/postgres-tools

RUN set -eux; \
  apt-get update; \
  apt-get install --no-install-recommends -y \
    ca-certificates \
    wget\
  ; \
  apt autoremove -y

# Install the Backblaze B2 CLI
ARG B2_VERSION="3.9.0"
RUN set -eux; \
  wget -O /usr/bin/b2 "https://github.com/Backblaze/B2_Command_Line_Tool/releases/download/v${B2_VERSION}/b2-linux"; \
  chmod +x /usr/bin/b2

COPY --link files/pg-backup.sh /opt/postgres-tools/

ENV \
  B2_BUCKET="pie-gd-backups" \
  PGDATABASE="pie_gd_mastodon" \
  PGHOST="pie-gd-postgres15.internal" \
  PGPORT="5432" \
  PGUSER="postgres"

ENTRYPOINT []
