#!/usr/bin/env bash

# Creates a timestamped backup of the Mastodon Postgres database in the
# `backups/postgres` directory.
#
# Usage: pg-backup.sh

set -e

REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. >/dev/null 2>&1 && pwd )"

mkdir -p "$REPO_DIR"/backups/postgres
fly proxy 5432 --app pie-gd-postgres &

# Wait for Postgres to be available on port 5432.
while ! nc -z localhost 5432; do
  sleep 1
done

FILENAME="$REPO_DIR"/backups/postgres/pie_gd_mastodon-"$(date +%Y%m%d_%H%M%S)".sqlc

pg_dump \
  --host=localhost \
  --file="$FILENAME" \
  --format=c \
  --port=5432 \
  --username=postgres pie_gd_mastodon \
|| (kill $! && rm -f "$FILENAME" && exit 1)

kill %1
echo "Backup created: $FILENAME"
