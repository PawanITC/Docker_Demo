# Redis 7 with persistence turned on (RDB snapshots + AOF log).
FROM redis:7.4-alpine

ENV REDIS_PASSWORD=redis

COPY redis.conf /usr/local/etc/redis/redis.conf

# RDB/AOF files are written here.
VOLUME /data

EXPOSE 6379

# Shell form so $REDIS_PASSWORD is expanded at start-up.
CMD ["sh", "-c", "exec redis-server /usr/local/etc/redis/redis.conf --requirepass \"$REDIS_PASSWORD\""]
