#!/usr/bin/env bash

# Creates a timestamped backup of the Mastodon Postgres database and uploads it
# to Backblaze B2.
#
# Requires the `fly`, `pg_dump` and `b2` CLI tools, and expects B2 to already be
# authorized to upload to the specified bucket.
#
# Usage: pg-backup.sh

set -e

DB_NAME=pie_gd_mastodon
B2_BUCKET=pie-gd-backups
B2_FILENAME="$DB_NAME"-$(date +%Y%m%d_%H%M%S).sqlc
FLY_APP=pie-gd-postgres15

echo "=> Opening a local proxy to the database"
fly proxy 5432 --app "$FLY_APP" &

# Wait for Postgres to be available on port 5432.
while ! nc -z localhost 5432; do
  sleep 1
done

TMPFILE=$(mktemp)

echo "=> Dumping $DB_NAME"
pg_dump \
  --host=localhost \
  --file="$TMPFILE" \
  --format=c \
  --port=5432 \
  --username=postgres \
  --verbose \
  "$DB_NAME" \
  || (kill $! && rm -f "$TMPFILE" && exit 1)

echo "=> Closing proxy"
kill %1

echo "=> Uploading $B2_FILENAME to B2 bucket $B2_BUCKET"
b2 upload-file "$B2_BUCKET" "$TMPFILE" "$B2_FILENAME" \
  || (rm -f "$TMPFILE" && exit 1)

rm -f "$TMPFILE"
echo "=> Done!"
