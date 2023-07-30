# Postgres Tools

This is a Fly app that's used to host Fly Machines for running Postgres maintenance tasks, such as performing DB backups to Backblaze B2.

## Initial Setup

```bash
fly apps create \
  --machines \
  --org pie-gd \
  --name pie-gd-postgres-tools

fly secrets set \
  --stage \
  B2_APPLICATION_KEY_ID=<redacted> \
  B2_APPLICATION_KEY=<redacted> \
  PGPASSWORD=<redacted>
```

## Creating a Database Backup

The following command will launch a one-off machine, dump the Mastodon database, upload the backup to Backblaze B2, and then destroy the machine.

```bash
fly machine run \
  --name pg-backup \
  --restart no \
  --rm \
  . \
  ./pg-backup.sh

fly logs
```
