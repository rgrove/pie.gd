# syntax=docker/dockerfile:1
FROM docker.elastic.co/elasticsearch/elasticsearch:8.9.0
USER root
COPY --link bin/* /app/bin/
COPY --link limits.conf /etc/security/limits.conf
ENTRYPOINT ["/app/bin/docker-entrypoint"]
