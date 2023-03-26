# Maintenance

## Postgres

The `pg_dump` and `pg_restore` tools are used to backup and restore the Postgres DB. You can install these tools with Homebrew on macOS without needing to install Postgres itself:

```bash
brew install libpq
```

### Backing up

Create a Postgres backup:

```bash
scripts/pg-backup.sh
```

You'll be prompted for the Postgres password.

This script uses `pg_dump` to produce a timestamped, compressed Postgres DB dump and upload it to Backblaze B2 for safekeeping.

More information on `pg_dump`:

- [A better backup with PostgreSQL using pg_dump](https://www.commandprompt.com/blog/a_better_backup_with_postgresql_using_pg_dump/)

### Restoring

To communicate with Postgres, first open a local proxy:

```bash
fly proxy 5432 --app pie-gd-postgres15
```

Restore a Postgres backup:

```bash
pg_restore --username=postgres --dbname=pie_gd_mastodon <filename>
```
