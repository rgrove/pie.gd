# syntax=docker/dockerfile:1
FROM redis:7.2.3-alpine
ARG TARGETARCH

RUN apk add --no-cache gzip tar wget

# Install Hivemind
ARG HIVEMIND_VERSION="1.1.0"
RUN \
  wget -O - "https://github.com/DarthSim/hivemind/releases/download/v${HIVEMIND_VERSION}/hivemind-v${HIVEMIND_VERSION}-linux-${TARGETARCH}.gz" \
    | gunzip --stdout > /usr/bin/hivemind && \
  chmod +x /usr/bin/hivemind

# Install Redis Exporter
ARG REDIS_EXPORTER_VERSION="1.55.0"
RUN \
  wget -O - "https://github.com/oliver006/redis_exporter/releases/download/v${REDIS_EXPORTER_VERSION}/redis_exporter-v${REDIS_EXPORTER_VERSION}.linux-${TARGETARCH}.tar.gz" \
    | tar -xz -C /usr/bin --strip-components=1 "redis_exporter-v${REDIS_EXPORTER_VERSION}.linux-${TARGETARCH}/redis_exporter" && \
  chmod +x /usr/bin/redis_exporter

COPY --link Procfile /app/
COPY --link --chmod=755 bin/* /app/bin/

WORKDIR /app
CMD ["hivemind"]
