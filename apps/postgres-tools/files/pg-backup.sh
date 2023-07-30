#!/usr/bin/env bash

# Creates a timestamped backup of the Postgres DB specified in the `PGDATABASE`
# env var and uploads it to Backblaze B2.
#
# Usage: pg-backup.sh

set -e

B2_FILENAME="postgres/$PGDATABASE"-$(date +%Y%m%d_%H%M%S).sqlc
TMPFILE=$(mktemp)

echo "=> Dumping $PGDATABASE"
pg_dump \
  --file="$TMPFILE" \
  --format=c \
  --verbose \
  "$PGDATABASE" \
  || (kill $! && rm -f "$TMPFILE" && exit 1)

echo "=> Uploading to B2: $B2_BUCKET/$B2_FILENAME"
b2 upload-file "$B2_BUCKET" "$TMPFILE" "$B2_FILENAME" \
  || (rm -f "$TMPFILE" && exit 1)

rm -f "$TMPFILE"
echo "=> Done!"
