# pie.gd Mastodon Instance

[pie.gd](https://pie.gd) is my private Mastodon instance hosted on [Fly.io](https://fly.io).

This repository contains the various config files, scripts, and documentation that I use to run pie.gd. I'm sharing it because other people running Mastodon instances might find it helpful, but this isn't intended to be a general purpose plug-and-play Mastodon setup; it's very specific to my instance.

I've enjoyed learning more about Rails, Sidekiq, and Postgres, which I hadn't previously used much.

## Acknowledgments

When I first set out to run a Mastodon instance on Fly.io a few weeks ago I did some searching to see if there was prior art, and I found Aman Gupta Karmani's [tmm1/flyapp-mastodon](https://github.com/tmm1/flyapp-mastodon) repo, which was a tremendous help in getting started.

In the weeks since I first began running this server I've seen a few other people post about their own Mastodon instances on Fly.io, and I was fascinated to see some of the similarities and differences in how we solved the same problems.

André Arko's [fantastic pull request](https://github.com/tmm1/flyapp-mastodon/pull/2) against tmm1/flyapp-mastodon — which I discovered while writing this readme! — both validates some of the solutions I wasn't quite sure about (like using Caddy as an in-VM reverse proxy and Hivemind as a process manager) and offers new solutions to problems I haven't solved yet (like how to scale Sidekiq and the Rails app).

I'm grateful to everyone who has shared their work, and I've tried to give credit in this readme and in commit messages where appropriate (and will continue to do so). In that spirit, I hope you'll also feel free to use anything you learn from this repo.

## Overview

I use Fly.io to run a small private Mastodon instance using the [official Mastodon Docker image](https://hub.docker.com/r/tootsuite/mastodon). Currently, this involves running 4 Fly.io virtual machines divided across 3 apps:

- `pie-gd-mastodon`: This app uses the same Mastodon Docker image to run different processes in two separate VMs:

  - `mastodon` (shared-cpu-1x, 1GB RAM): [Caddy](https://caddyserver.com/) reverse proxy, Mastodon Rails app, and Mastodon Node.js streaming server.

  - `sidekiq` (shared-cpu-1x, 1GB RAM): Sidekiq job processor.

- `pie-gd-postgres` (shared-cpu-1x, 512MB RAM x 2): Postgres database, created using [`fly pg create`](https://fly.io/docs/postgres/) and later scaled up. This is a cluster consisting of a primary and a replica, each with a 3GB persistent disk volume attached.

- `pie-gd-redis` (shared-cpu-1x, 256MB RAM): Redis server. This app has a 1GB persistent disk volume attached to it.

Media is stored in [Backblaze B2](https://www.backblaze.com/b2/cloud-storage.html), which has an S3-compatible API that Mastodon can use (and lower storage fees than S3).

I use [Cloudflare](https://www.cloudflare.com/) as a CDN in front of the Backblaze B2 bucket. Since Backblaze is part of Cloudflare's [Bandwidth Alliance](https://www.cloudflare.com/bandwidth-alliance/), egress charges from B2 are waived, which means serving media files costs me nothing.

Why use Caddy in the `mastodon` VM when Fly.io already provides a reverse proxy? Two reasons:

1. We need to be able to forward requests to both the Mastodon Rails app and the Node.js streaming server.

2. Mastodon's rate limiting and abuse prevention features rely on being able to trust the [`x-forwarded-for`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Forwarded-For) header to determine the client's IP address, and Fly.io happily passes through any `x-forwarded-for` value the client sends, which makes it spoofable.

Caddy is configured to replace the `x-forwarded-for` header with the value of the `fly-client-ip` header, which can't be spoofed by the client. And since it's already there, I also use Caddy to serve static assets with far-future `cache-control` headers.

## Initial Setup

This was adapted from [tmm1/flyapp-mastodon](https://github.com/tmm1/flyapp-mastodon), which I found extremely helpful!

I only did this once, and these steps are included here mainly for reference. Fly.io may introduce changes over time, so these steps may or may not continue to work the way they did when I initially set up pie.gd.

### App

```bash
fly apps create --org pie-gd --name pie-gd-mastodon
fly regions add sea
fly ips allocate-v4 --region sea
fly ips allocate-v6
fly scale memory 1024
```

After pointing DNS at the app, create a TLS certificate:

```bash
fly certs create pie.gd
```

### Secrets

```bash
SECRET_KEY_BASE=$(docker run --rm -it tootsuite/mastodon:latest bin/rake secret)
OTP_SECRET=$(docker run --rm -it tootsuite/mastodon:latest bin/rake secret)

fly secrets set \
  OTP_SECRET=$OTP_SECRET \
  SECRET_KEY_BASE=$SECRET_KEY_BASE

docker run \
  --rm \
  -it \
  -e OTP_SECRET=$OTP_SECRET \
  -e SECRET_KEY_BASE=$SECRET_KEY_BASE \
  tootsuite/mastodon:latest \
  bin/rake mastodon:webpush:generate_vapid_key \
| sed 's/\r//' \
| fly secrets import
```

### Redis

```bash
fly apps create --org pie-gd --name pie-gd-redis
fly regions add sea --config apps/redis/fly.toml
fly volumes create mastodon_redis --config apps/redis/fly.toml --region sea --size 1
fly deploy apps/redis
```

### Postgres

```bash
fly pg create --org pie-gd --name pie-gd-postgres --region sea
fly pg attach --app pie-gd-mastodon pie-gd-postgres
```

### Upload Storage

Uploads are stored in Backblaze B2 in the `pie-gd-uploads` bucket.

The access key id and secret are set as Fly secrets in the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables.

Cloudflare is configured to proxy the `files.pie.gd` subdomain to the `pie-gd-uploads` bucket, and there's a URL rewrite transform rule that adds a `/file/pie-gd-uploads` prefix to the path of each request so that it maps to Backblaze's path structure.

### Email

Mastodon is configured to use [Postmark](https://postmarkapp.com/) to send emails via SMTP. Setting up a Postmark account is out of scope for this readme, but it's not hard.

This is probably not actually necessary for a private single-user Mastodon server, since the only thing you really need email for is the confirmation email when you create your account. You could just skip this and use `tootctl` to manually create the account. But it'll be necessary if you ever invite other users to your server, or if you're running a public instance.

### Initial Deployment

To create the DB schema and run the initial migrations, I temporarily added the following release command to `fly.toml`:

```toml
[deploy]
  release_command = "bundle exec rails db:setup"
```

Then I deployed the app:

```bash
fly deploy
```

After the initial deployment, I removed the `[deploy]` section from `fly.toml`, since the DB setup only needs to happen once.

Once the server is running, you can use `fly ssh console` to SSH into the running app and run `tootctl` commands to grant the Owner role to your account. See the [Mastodon documentation](https://docs.joinmastodon.org/admin/setup/) for details.

## Maintenance

See [MAINTENANCE.md](MAINTENANCE.md) for documentation on maintenance tasks like backing up and restoring the database.
