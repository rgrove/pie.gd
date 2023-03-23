# syntax=docker/dockerfile:1
FROM redis:7.0.9-alpine
COPY start-redis /usr/bin/
RUN chmod +x /usr/bin/start-redis
CMD ["start-redis"]
