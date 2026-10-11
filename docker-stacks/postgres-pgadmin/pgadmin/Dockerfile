# pgAdmin 4 with the Postgres server pre-registered (no manual "Add Server").
FROM dpage/pgadmin4:8

ENV PGADMIN_DEFAULT_EMAIL=admin@example.com \
    PGADMIN_DEFAULT_PASSWORD=admin \
    PGADMIN_CONFIG_SERVER_MODE=False \
    PGADMIN_CONFIG_MASTER_PASSWORD_REQUIRED=False

# pgAdmin imports this file on first start.
COPY servers.json /pgadmin4/servers.json

# pgAdmin's settings, saved queries and session data.
VOLUME /var/lib/pgadmin

EXPOSE 80
