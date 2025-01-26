# pie.gd Postgres App

## How to Deploy `fly.toml` Config Changes

Since Fly Managed Postgres apps don't have Dockerfiles, you need to specify a Docker image explicitly in order to deploy changes to `fly.toml`.

To see what image the app is currently using, run (in this directory):

```sh
fly image show
```

Then, to deploy `fly.toml` changes:

```sh
fly deploy --image <repository>:<tag>
```

For example, if the app is currently using `flyio/postgres-flex:15.8`, you can deploy changes with:

```sh
fly deploy --image flyio/postgres-flex:15.8
```

## How to Fix a Cluster Stuck in a Read-Only State

If the primary node in the cluster exceeds 90% disk usage, the database will be put into a read-only state. Once this happens, write operations will begin to fail with log messages like:

```
ERROR:  cannot execute INSERT in a read-only transaction
```

If you see these errors in the log, first verify that these operations are actually being attempted on the primary and not on a replica. If the logs are coming from a replica, then Mastodon may be misconfigured and attempting to write to a replica instead of the primary. If the logs are coming from the primary, then you'll need to run a few commands to make the database writable again.

First, connect Postgres on the primary node using psql:

```sh
fly pg connect
```

Next, open the Mastodon database and check its read-only status:

```sql
\connect pie_gd_mastodon
show default_transaction_read_only;
```

If this returns `on`, then you'll need to run the following command to make the Mastodon database writable again during the current connection:

```sql
set default_transaction_read_only = off;
```

Next, persist these changes beyond the current connection:

```sql
alter database pie_gd_mastodon set default_transaction_read_only = off;
```

Exit psql:

```sql
exit
```

Finally, a restart may be necessary in order for the changes to take effect (possibly just because it will kill existing connections?):

```sh
fly pg restart
```

These instructions were derived from [this PagerTree post-mortem](https://pagertree.com/blog/fly.io-migrate-to-v2-postgres-stuck-in-read-only-mode), and [this Fly community post](https://community.fly.io/t/pg-stuck-in-a-read-only-state/21582/4), both of which I found very helpful.
