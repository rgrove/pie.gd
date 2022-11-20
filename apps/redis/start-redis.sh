#!/bin/sh

# Runs Redis in a Docker container.
#
# Usage: start-redis.sh

sysctl vm.overcommit_memory=1
sysctl net.core.somaxconn=1024

redis-server \
  --appendonly yes \
  --dir /data/
