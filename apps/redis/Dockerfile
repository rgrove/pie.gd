# syntax=docker/dockerfile:1
FROM redis:7.0.8-alpine
COPY start-redis.sh /usr/bin/
RUN chmod +x /usr/bin/start-redis.sh
CMD ["start-redis.sh"]
