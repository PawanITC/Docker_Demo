# PostgreSQL 16 with a seed script that runs on FIRST start only
# (i.e. when the data volume is empty).
FROM postgres:16-alpine

ENV POSTGRES_USER=postgres \
    POSTGRES_PASSWORD=postgres \
    POSTGRES_DB=appdb

# Every *.sql / *.sh file in this folder runs once, in alphabetical order.
COPY init/ /docker-entrypoint-initdb.d/

# Database files live here → mount a volume so data survives container removal.
VOLUME /var/lib/postgresql/data

EXPOSE 5432
