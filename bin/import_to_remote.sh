#!/usr/bin/env bash
#
# Exports local development data and imports it into a remote PostgreSQL database.
#
# Usage:
#   bin/import_to_remote.sh "postgresql://user:pass@host/dbname?sslmode=require"
#
# The connection string is the DATABASE_URL from your Neon dashboard.

set -o errexit

TARGET_URL="${1}"

if [ -z "$TARGET_URL" ]; then
  echo "Error: no target database URL provided."
  echo ""
  echo "Usage: bin/import_to_remote.sh \"postgresql://...\""
  echo ""
  echo "Copy the connection string from your Neon dashboard."
  exit 1
fi

LOCAL_DB="boule_app_development"
DUMP_FILE="tmp/data_export.sql"

echo "==> Exporting local database '$LOCAL_DB'..."
pg_dump "$LOCAL_DB" \
  --data-only \
  --no-owner \
  --no-acl \
  --exclude-table=schema_migrations \
  --exclude-table=ar_internal_metadata \
  > "$DUMP_FILE"

echo "==> Importing into remote database..."
psql "$TARGET_URL" < "$DUMP_FILE"

echo "==> Cleaning up..."
rm "$DUMP_FILE"

echo ""
echo "Done. All local data has been imported into the remote database."
